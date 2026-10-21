import Foundation

public final class Gateway {
    public struct Options: Sendable {
        public var uplink: String?
        public var wifiInterface: String?
        public var resolver: String?

        public init(uplink: String? = nil, wifiInterface: String? = nil, resolver: String? = nil) {
            self.uplink = uplink
            self.wifiInterface = wifiInterface
            self.resolver = resolver
        }
    }

    public static let bridgeName = "bridge100"

    let options: Options
    let hub = EventHub()
    let undo = Undo()
    var signalSource: SignalSource?
    var watcher: NetworkWatcher?
    var wifiBridge: WiFiEventBridge?

    public init(options: Options) {
        self.options = options
    }

    public func up() async throws {
        try Privilege.requireRoot()

        if let stale = RunState.load() {
            if Self.isOurProcess(stale.pid) {
                throw GatewayError.alreadyRunning(stale.pid)
            }
            Console.warn(String(localized: "state file from an unclean shutdown; recovering first", bundle: L10n.bundle))
            await teardown(from: stale)
        }

        guard let snapshot = InternetSharing.loadSnapshot(from: Paths.snapshotURL) else {
            throw GatewayError.missingSnapshot
        }
        guard let uplink = options.uplink ?? NATConfig.primaryDevice(snapshot) else {
            throw GatewayError.noUplink
        }
        let resolver = options.resolver ?? "1.1.1.1"
        let wifi = try WiFi(interfaceName: options.wifiInterface)

        signalSource = SignalSource(hub: hub)
        let watcher = NetworkWatcher(hub: hub)
        watcher.start()
        self.watcher = watcher
        let wifiBridge = WiFiEventBridge(hub: hub)
        wifiBridge.install()
        self.wifiBridge = wifiBridge

        var state = RunState(
            pid: getpid(),
            startedAt: Date(),
            uplink: uplink,
            wifiInterface: wifi.name,
            natEnabled: false,
            dnsOverride: nil
        )

        do {
            try await bringUp(wifi: wifi, uplink: uplink, resolver: resolver, snapshot: snapshot, state: &state)
        } catch {
            await teardown()
            throw error
        }

        await supervise(wifi: wifi, uplink: uplink)
        await teardown()
    }

    private func bringUp(
        wifi: WiFi,
        uplink: String,
        resolver: String,
        snapshot: [String: Any],
        state: inout RunState
    ) async throws {
        Console.step(String(localized: "preparing Wi-Fi interface \(wifi.name)", bundle: L10n.bundle))
        try wifi.setPower(true)
        wifi.disassociate()
        undo.push(String(localized: "restore Wi-Fi power", bundle: L10n.bundle)) {
            try wifi.setPower(false)
            try await Task.sleep(for: .seconds(2))
            try wifi.setPower(true)
        }

        do {
            try await waitUntil(String(localized: "uplink \(uplink) has link and IPv4", bundle: L10n.bundle), timeout: .seconds(25)) {
                NetworkState.linkActive(uplink) && !NetworkState.ipv4Addresses(uplink).isEmpty
            }
        } catch let error as GatewayError {
            guard case .timeout = error else { throw error }
            throw GatewayError.uplinkDown(uplink)
        }

        wifi.disassociate()

        Console.step(String(localized: "overriding DNS on \(uplink) to \(resolver)", bundle: L10n.bundle))
        let record = try DNSOverride.apply(resolver: resolver, toInterface: uplink)
        state.dnsOverride = record
        undo.push(String(localized: "restore DNS on \(uplink)", bundle: L10n.bundle)) {
            try DNSOverride.restore(record)
        }
        try state.save()

        do {
            if try !APPassword.exists(for: wifi.name) {
                Console.warn(String(localized: "no Internet-sharing password in the System keychain for \(wifi.name); set the Wi-Fi password once in System Settings > General > Sharing > Internet Sharing", bundle: L10n.bundle))
            }
        } catch {
            Console.warn(String(localized: "could not check the System keychain: \(String(describing: error))", bundle: L10n.bundle))
        }

        let sharing = try InternetSharing()
        Console.step(String(localized: "enabling Internet sharing on \(wifi.name)", bundle: L10n.bundle))
        try sharing.write(NATConfig.enabled(snapshot, sharingDevices: [wifi.name]))
        undo.push(String(localized: "disable Internet sharing", bundle: L10n.bundle)) {
            let sharing = try InternetSharing()
            try sharing.write(NATConfig.disabled(try sharing.read()))
        }
        state.natEnabled = true
        try state.save()

        try await waitUntil(String(localized: "sharing bridge \(Self.bridgeName) is up", bundle: L10n.bundle), timeout: .seconds(15)) {
            !NetworkState.ipv4Addresses(Self.bridgeName).isEmpty
        }

        var tunnel = Self.tunnelInterface()
        if tunnel == nil {
            do {
                try await waitUntil(String(localized: "a VPN tunnel owns the default route", bundle: L10n.bundle), timeout: .seconds(10)) {
                    Self.tunnelInterface() != nil
                }
            } catch let error as GatewayError {
                guard case .timeout = error else { throw error }
                Console.info(String(localized: "No tunnel yet. Start your VPN now; waiting (Ctrl-C to abort).", bundle: L10n.bundle))
                try await waitUntil(String(localized: "a VPN tunnel owns the default route", bundle: L10n.bundle), timeout: nil) {
                    Self.tunnelInterface() != nil
                }
            }
            tunnel = Self.tunnelInterface()
        }
        Console.ok(String(localized: "default route via \(tunnel ?? "unknown")", bundle: L10n.bundle))

        Console.step(String(localized: "probing the tunnel exit", bundle: L10n.bundle))
        let probe = await ExitProbe.probe()
        report(probe, stage: String(localized: "exit", bundle: L10n.bundle))

        let bridgeAddrs = NetworkState.ipv4Addresses(Self.bridgeName)
        Console.info("")
        Console.info(String(localized: "up: uplink=\(uplink) bridge=\(bridgeAddrs.first ?? "-") tunnel=\(tunnel ?? "-") resolver=\(resolver)", bundle: L10n.bundle))
        Console.info(String(localized: "exit: \(probe.byIP?.ip ?? "-") \(probe.byIP?.loc ?? "")", bundle: L10n.bundle))
        try state.save()
    }

    private func supervise(wifi: WiFi, uplink: String) async {
        struct Observed {
            var uplinkUp: Bool
            var bridgeUp: Bool
            var tunnel: String?
        }
        func observe() -> Observed {
            Observed(
                uplinkUp: NetworkState.linkActive(uplink) && !NetworkState.ipv4Addresses(uplink).isEmpty,
                bridgeUp: !NetworkState.ipv4Addresses(Self.bridgeName).isEmpty,
                tunnel: Self.tunnelInterface()
            )
        }

        Console.info(String(localized: "supervising; Ctrl-C to stop", bundle: L10n.bundle))
        var state = observe()
        var heartbeat = hub.scheduleTimeout(after: .seconds(30))
        while let event = await hub.next() {
            if case .timeout(let tid) = event, tid == heartbeat {
                heartbeat = hub.scheduleTimeout(after: .seconds(30))
            }
            switch event {
            case .signal(let sig):
                hub.cancelTimeout(heartbeat)
                Console.info(String(localized: "signal \(String(describing: sig)) received; shutting down", bundle: L10n.bundle))
                return
            case .wifi(let wifiEvent):
                Console.info(String(localized: "wifi \(String(describing: wifiEvent)): mode=\(wifi.mode) service=\(String(describing: wifi.serviceActive)) power=\(wifi.powerOn ? "on" : "off")", bundle: L10n.bundle))
            case .network, .timeout:
                let next = observe()
                if next.tunnel != state.tunnel {
                    switch (state.tunnel, next.tunnel) {
                    case (.some, .none):
                        Console.warn(String(localized: "tunnel lost", bundle: L10n.bundle))
                    case (_, .some(let name)):
                        Console.ok(String(localized: "tunnel back: \(name); re-probing", bundle: L10n.bundle))
                        report(await ExitProbe.probe(), stage: String(localized: "exit", bundle: L10n.bundle))
                    case (.none, .none):
                        break
                    }
                }
                if next.uplinkUp != state.uplinkUp {
                    next.uplinkUp
                        ? Console.ok(String(localized: "uplink restored", bundle: L10n.bundle))
                        : Console.warn(String(localized: "uplink lost", bundle: L10n.bundle))
                }
                if next.bridgeUp != state.bridgeUp {
                    next.bridgeUp
                        ? Console.ok(String(localized: "sharing bridge back", bundle: L10n.bundle))
                        : Console.warn(String(localized: "sharing bridge down", bundle: L10n.bundle))
                }
                state = next
            }
        }
    }

    private func report(_ result: ProbeResult, stage: String) {
        if let byIP = result.byIP {
            let loc = byIP.loc.map { " (\($0))" } ?? ""
            Console.ok(String(localized: "\(stage) IP \(byIP.ip)\(loc)", bundle: L10n.bundle))
        } else {
            Console.warn(String(localized: "tunnel is up but no internet through it", bundle: L10n.bundle))
        }
        if result.byName == nil {
            Console.warn(String(localized: "DNS does not resolve through the tunnel", bundle: L10n.bundle))
        }
    }

    static func tunnelInterface() -> String? {
        guard let name = try? DefaultRoute.interface(), name.hasPrefix("utun") else { return nil }
        return name
    }

    public static func pidAlive(_ pid: Int32) -> Bool {
        if kill(pid, 0) == 0 { return true }
        return errno == EPERM
    }

    public static func isOurProcess(_ pid: Int32) -> Bool {
        // TODO(TD-1): executable basenames only; a renamed or symlinked binary is a blind spot
        guard pidAlive(pid),
              let ours = processPath(getpid()),
              let theirs = processPath(pid) else { return false }
        return URL(fileURLWithPath: ours).lastPathComponent
            == URL(fileURLWithPath: theirs).lastPathComponent
    }

    private static func processPath(_ pid: Int32) -> String? {
        var buf = [UInt8](repeating: 0, count: Int(MAXPATHLEN))
        guard proc_pidpath(pid, &buf, UInt32(buf.count)) > 0 else { return nil }
        return String(decoding: buf.prefix { $0 != 0 }, as: UTF8.self)
    }
}

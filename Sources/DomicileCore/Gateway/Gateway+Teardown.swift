import Foundation

extension Gateway {
    func teardown() async {
        watcher?.stop()
        watcher = nil
        wifiBridge?.uninstall()
        wifiBridge = nil
        signalSource = nil
        await undo.unwindAll()
        RunState.remove()
        Console.info(String(localized: "stopped", bundle: L10n.bundle))
    }

    func teardown(from state: RunState) async {
        if let record = state.dnsOverride {
            do {
                try DNSOverride.restore(record)
                Console.ok(String(localized: "restored DNS on \(state.uplink)", bundle: L10n.bundle))
            } catch {
                Console.warn(String(localized: "could not restore DNS on \(state.uplink): \(String(describing: error))", bundle: L10n.bundle))
            }
        }
        if state.natEnabled {
            do {
                let sharing = try InternetSharing()
                try sharing.write(NATConfig.disabled(try sharing.read()))
                Console.ok(String(localized: "Internet sharing disabled", bundle: L10n.bundle))
            } catch {
                Console.warn(String(localized: "could not disable Internet sharing: \(String(describing: error))", bundle: L10n.bundle))
            }
        }
        if let wifi = try? WiFi(interfaceName: state.wifiInterface) {
            try? wifi.setPower(false)
            try? await Task.sleep(for: .seconds(2))
            try? wifi.setPower(true)
            Console.ok(String(localized: "Wi-Fi power-cycled on \(state.wifiInterface)", bundle: L10n.bundle))
        }
        RunState.remove()
    }

    public func down() async throws {
        try Privilege.requireRoot()
        guard let state = RunState.load() else {
            Console.info(String(localized: "nothing is running", bundle: L10n.bundle))
            return
        }
        if Self.isOurProcess(state.pid) {
            Console.step(String(localized: "stopping supervisor (pid \(String(describing: state.pid)))", bundle: L10n.bundle))
            kill(state.pid, SIGTERM)
            var waited: Duration = .zero
            while Self.isOurProcess(state.pid), waited < .seconds(10) {
                try? await Task.sleep(for: .milliseconds(200))
                waited += .milliseconds(200)
            }
            if Self.isOurProcess(state.pid) {
                Console.warn(String(localized: "supervisor did not exit in 10s; tearing down directly", bundle: L10n.bundle))
            } else {
                Console.ok(String(localized: "stopped supervisor", bundle: L10n.bundle))
            }
        }
        if let remaining = RunState.load() {
            await teardown(from: remaining)
        }
    }
}

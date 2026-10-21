import ArgumentParser
import DomicileCore
import Foundation

struct StatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: String(localized: "Show the gateway state. Works without root.", bundle: L10n.bundle)
    )

    @Flag(help: ArgumentHelp(String(localized: "Also probe the tunnel exit over the network", bundle: L10n.bundle)))
    var probe = false

    func run() async throws {
        if let wifi = try? WiFi(interfaceName: nil) {
            Console.info(String(localized: "wifi      \(wifi.name) power=\(wifi.powerOn ? "on" : "off") mode=\(wifi.mode) service=\(String(describing: wifi.serviceActive))", bundle: L10n.bundle))
        } else {
            Console.info(String(localized: "wifi      none", bundle: L10n.bundle))
        }

        if let sharing = try? InternetSharing(), let nat = try? sharing.read() {
            let devices = nat["SharingDevices"] as? [String] ?? []
            Console.info(String(localized: "sharing   enabled=\(String(describing: NATConfig.isEnabled(nat))) devices=\(devices.joined(separator: ",")) primary=\(NATConfig.primaryDevice(nat) ?? "-")", bundle: L10n.bundle))
        } else {
            Console.info(String(localized: "sharing   unreadable (needs sudo)", bundle: L10n.bundle))
        }

        let snapshot = InternetSharing.loadSnapshot(from: Paths.snapshotURL)
        let runState = RunState.load()
        let uplink = runState?.uplink
            ?? snapshot.flatMap(NATConfig.primaryDevice)
            ?? NetworkState.primaryInterface()

        if let uplink {
            let addrs = NetworkState.ipv4Addresses(uplink)
            Console.info(String(localized: "uplink    \(uplink) link=\(NetworkState.linkActive(uplink) ? "active" : "inactive") ipv4=\(addrs.joined(separator: ","))", bundle: L10n.bundle))
            if let found = try? NetworkServices.find(bsdName: uplink) {
                let servers = NetworkServices.dnsConfiguration(of: found.service)?["ServerAddresses"] as? [String] ?? []
                Console.info(String(localized: "service   \(NetworkServices.name(of: found.service)) [\(NetworkServices.serviceID(of: found.service))] dns=\(servers.isEmpty ? "dhcp" : servers.joined(separator: ","))", bundle: L10n.bundle))
            } else {
                Console.info(String(localized: "service   none for \(uplink)", bundle: L10n.bundle))
            }
        } else {
            Console.info(String(localized: "uplink    unknown", bundle: L10n.bundle))
        }

        let bridge = NetworkState.ipv4Addresses(Gateway.bridgeName)
        Console.info(String(localized: "bridge    \(Gateway.bridgeName) ipv4=\(bridge.isEmpty ? "-" : bridge.joined(separator: ","))", bundle: L10n.bundle))

        if let route = try? DefaultRoute.interface() {
            let tunnel = route.hasPrefix("utun") ? " tunnel" : ""
            Console.info(String(localized: "route     1.1.1.1 via \(route)\(tunnel)", bundle: L10n.bundle))
        } else {
            Console.info(String(localized: "route     1.1.1.1 unresolved", bundle: L10n.bundle))
        }

        let dns = NetworkState.globalDNSServers()
        Console.info(String(localized: "dns       \(dns.isEmpty ? "-" : dns.joined(separator: ","))", bundle: L10n.bundle))

        Console.info(String(localized: "snapshot  \(snapshot == nil ? "missing" : "present") (\(Paths.snapshotURL.path))", bundle: L10n.bundle))

        if let runState {
            let label: String
            if Gateway.isOurProcess(runState.pid) {
                label = String(localized: "alive", bundle: L10n.bundle)
            } else {
                label = Gateway.pidAlive(runState.pid)
                    ? String(localized: "stale (pid reused)", bundle: L10n.bundle)
                    : String(localized: "stale", bundle: L10n.bundle)
            }
            Console.info(String(localized: "run state pid=\(String(describing: runState.pid)) \(label) started=\(String(describing: runState.startedAt))", bundle: L10n.bundle))
        } else {
            Console.info(String(localized: "run state none", bundle: L10n.bundle))
        }

        if probe {
            Console.step(String(localized: "probing the tunnel exit", bundle: L10n.bundle))
            let result = await ExitProbe.probe()
            if let byIP = result.byIP {
                Console.info(String(localized: "exit ip   \(byIP.ip) loc=\(byIP.loc ?? "-") colo=\(byIP.colo ?? "-")", bundle: L10n.bundle))
            } else {
                Console.info(String(localized: "exit ip   no answer by IP", bundle: L10n.bundle))
            }
            if let byName = result.byName {
                Console.info(String(localized: "exit name \(byName.ip) loc=\(byName.loc ?? "-") colo=\(byName.colo ?? "-")", bundle: L10n.bundle))
            } else {
                Console.info(String(localized: "exit name no answer by name (DNS)", bundle: L10n.bundle))
            }
        }
    }
}

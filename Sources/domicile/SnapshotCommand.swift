import ArgumentParser
import DomicileCore

struct SnapshotCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "snapshot",
        abstract: String(localized: "Save the current NAT configuration as the reference snapshot. Requires root.", bundle: L10n.bundle)
    )

    func run() async throws {
        try Privilege.requireRoot()
        let sharing = try InternetSharing()
        try sharing.saveSnapshot(to: Paths.snapshotURL)
        let nat = try sharing.read()
        Console.ok(String(localized: "snapshot saved to \(Paths.snapshotURL.path)", bundle: L10n.bundle))
        Console.info(String(localized: "primary interface: \(NATConfig.primaryDevice(nat) ?? "-")", bundle: L10n.bundle))
        if let airport = nat["AirPort"] as? [String: Any] {
            Console.info(String(localized: "network name: \(airport["NetworkName"] as? String ?? "-")", bundle: L10n.bundle))
        }
    }
}

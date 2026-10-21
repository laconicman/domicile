import ArgumentParser
import DomicileCore

struct UpCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "up",
        abstract: String(localized: "Start Internet sharing and supervise the VPN tunnel. Requires root.", bundle: L10n.bundle)
    )

    @Option(help: ArgumentHelp(String(localized: "BSD name of the uplink interface (default: from the NAT snapshot)", bundle: L10n.bundle)))
    var uplink: String?

    @Option(help: ArgumentHelp(String(localized: "BSD name of the Wi-Fi interface (default: system Wi-Fi)", bundle: L10n.bundle)))
    var wifiInterface: String?

    @Option(help: ArgumentHelp(String(localized: "Resolver address applied to the uplink service (default: 1.1.1.1)", bundle: L10n.bundle)))
    var resolver: String?

    func run() async throws {
        try await Gateway(options: .init(
            uplink: uplink,
            wifiInterface: wifiInterface,
            resolver: resolver
        )).up()
    }
}

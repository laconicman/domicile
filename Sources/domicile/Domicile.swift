import ArgumentParser
import DomicileCore

@main
struct Domicile: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "domicile",
        abstract: String(localized: "Turn this Mac into a Wi-Fi gateway that exits through the VPN tunnel.", bundle: L10n.bundle),
        subcommands: [
            UpCommand.self,
            DownCommand.self,
            StatusCommand.self,
            SnapshotCommand.self,
        ],
        defaultSubcommand: StatusCommand.self
    )
}

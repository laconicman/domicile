import ArgumentParser
import DomicileCore

struct DownCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "down",
        abstract: String(localized: "Stop the supervisor, disable sharing, restore DNS and Wi-Fi. Requires root.", bundle: L10n.bundle)
    )

    func run() async throws {
        try await Gateway(options: .init()).down()
    }
}

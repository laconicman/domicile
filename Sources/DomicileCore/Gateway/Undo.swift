import Foundation

final class Undo {
    private var actions: [(name: String, run: () async throws -> Void)] = []

    func push(_ name: String, _ run: @escaping () async throws -> Void) {
        actions.append((name, run))
    }

    func unwindAll() async {
        while let action = actions.popLast() {
            do {
                try await action.run()
                Console.ok(String(localized: "undone: \(action.name)", bundle: L10n.bundle))
            } catch {
                Console.warn(String(localized: "undo '\(action.name)' failed: \(String(describing: error))", bundle: L10n.bundle))
            }
        }
    }
}

import Foundation

extension Gateway {
    func waitUntil(
        _ what: String,
        timeout: Duration?,
        heartbeat: Duration? = .seconds(5),
        _ condition: () throws -> Bool
    ) async throws {
        Console.step(what)
        if try condition() {
            Console.ok(what)
            return
        }
        let deadline = timeout.map { hub.scheduleTimeout(after: $0) }
        var beat = heartbeat.map { hub.scheduleTimeout(after: $0) }
        defer {
            if let deadline { hub.cancelTimeout(deadline) }
            if let beat { hub.cancelTimeout(beat) }
        }
        while let event = await hub.next() {
            switch event {
            case .signal(let sig):
                throw GatewayError.interrupted(sig)
            case .timeout(let tid):
                if tid == deadline { throw GatewayError.timeout(what) }
                if tid == beat {
                    beat = heartbeat.map { hub.scheduleTimeout(after: $0) }
                }
                if try condition() {
                    Console.ok(what)
                    return
                }
            default:
                if try condition() {
                    Console.ok(what)
                    return
                }
            }
        }
        throw GatewayError.interrupted(0)
    }
}

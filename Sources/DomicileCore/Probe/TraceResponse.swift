import Foundation

public struct TraceResponse: Sendable, Equatable {
    public var ip: String
    public var loc: String?
    public var colo: String?

    public init?(parsing text: String) {
        var ip: String?
        for line in text.split(whereSeparator: \.isNewline) {
            let fields = line.split(separator: "=", maxSplits: 1)
            guard fields.count == 2 else { continue }
            let value = String(fields[1])
            switch fields[0] {
            case "ip": ip = value
            case "loc": loc = value
            case "colo": colo = value
            default: break
            }
        }
        guard let ip else { return nil }
        self.ip = ip
    }
}

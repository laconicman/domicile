import Foundation

public struct RunState: Codable, Sendable, Equatable {
    public var pid: Int32
    public var startedAt: Date
    public var uplink: String
    public var wifiInterface: String
    public var natEnabled: Bool
    public var dnsOverride: DNSOverrideRecord?

    public init(
        pid: Int32,
        startedAt: Date,
        uplink: String,
        wifiInterface: String,
        natEnabled: Bool,
        dnsOverride: DNSOverrideRecord?
    ) {
        self.pid = pid
        self.startedAt = startedAt
        self.uplink = uplink
        self.wifiInterface = wifiInterface
        self.natEnabled = natEnabled
        self.dnsOverride = dnsOverride
    }

    public static func load() -> RunState? {
        guard let data = try? Data(contentsOf: Paths.runStateURL) else { return nil }
        return try? JSONDecoder().decode(RunState.self, from: data)
    }

    public func save() throws {
        try FileManager.default.createDirectory(
            at: Paths.stateDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o755]
        )
        let data = try JSONEncoder().encode(self)
        try data.write(to: Paths.runStateURL, options: .atomic)
    }

    public static func remove() {
        try? FileManager.default.removeItem(at: Paths.runStateURL)
    }
}

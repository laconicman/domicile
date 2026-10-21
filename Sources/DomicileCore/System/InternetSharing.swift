import Foundation
import SystemConfiguration

public struct InternetSharing {
    private let prefs: SCPreferences

    public init() throws {
        guard let prefs = SCPreferencesCreate(nil, "domicile" as CFString, "com.apple.nat.plist" as CFString) else {
            throw GatewayError.preferences(Self.errorDetail())
        }
        self.prefs = prefs
    }

    public func read() throws -> [String: Any] {
        guard let value = SCPreferencesGetValue(prefs, "NAT" as CFString) else {
            let status = SCError()
            guard status == Int32(kSCStatusOK) || status == Int32(kSCStatusNoKey) else {
                throw GatewayError.preferences(Self.errorDetail())
            }
            return [:]
        }
        return value as? [String: Any] ?? [:]
    }

    public func write(_ nat: [String: Any]) throws {
        guard SCPreferencesSetValue(prefs, "NAT" as CFString, nat as CFDictionary) else {
            throw GatewayError.preferences("set: \(Self.errorDetail())")
        }
        guard SCPreferencesCommitChanges(prefs) else {
            throw GatewayError.preferences("commit: \(Self.errorDetail())")
        }
        guard SCPreferencesApplyChanges(prefs) else {
            throw GatewayError.preferences("apply: \(Self.errorDetail())")
        }
    }

    public func saveSnapshot(to url: URL) throws {
        let nat = try read()
        guard NATConfig.isComplete(nat) else { throw GatewayError.incompleteSnapshot }
        let clean = NATConfig.sanitized(nat)
        let data = try PropertyListSerialization.data(fromPropertyList: clean, format: .xml, options: 0)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: url, options: .atomic)
    }

    public static func loadSnapshot(from url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let object = try? PropertyListSerialization.propertyList(from: data, format: nil) else {
            return nil
        }
        return object as? [String: Any]
    }

    private static func errorDetail() -> String {
        String(cString: SCErrorString(SCError()))
    }
}

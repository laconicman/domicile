import Foundation

public enum NATConfig {
    public static func isComplete(_ nat: [String: Any]) -> Bool {
        guard let primary = nat["PrimaryInterface"] as? [String: Any], !primary.isEmpty,
              let airport = nat["AirPort"] as? [String: Any], !airport.isEmpty else {
            return false
        }
        return true
    }

    public static func sanitized(_ nat: [String: Any]) -> [String: Any] {
        var copy = nat
        guard var airport = copy["AirPort"] as? [String: Any] else { return copy }
        airport.removeValue(forKey: "NetworkPassword")
        copy["AirPort"] = airport
        return copy
    }

    public static func enabled(_ nat: [String: Any], sharingDevices: [String]) -> [String: Any] {
        var copy = sanitized(nat)
        copy["Enabled"] = 1
        copy["SharingDevices"] = sharingDevices
        return copy
    }

    public static func disabled(_ nat: [String: Any]) -> [String: Any] {
        var copy = nat
        copy["Enabled"] = 0
        copy["SharingDevices"] = [String]()
        return copy
    }

    public static func primaryDevice(_ nat: [String: Any]) -> String? {
        (nat["PrimaryInterface"] as? [String: Any])?["Device"] as? String
    }

    public static func isEnabled(_ nat: [String: Any]) -> Bool {
        switch nat["Enabled"] {
        case let value as Int: return value == 1
        case let value as Bool: return value
        default: return false
        }
    }
}

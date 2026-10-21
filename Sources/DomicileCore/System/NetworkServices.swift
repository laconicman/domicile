import Foundation
import SystemConfiguration

public enum NetworkServices {
    public static func find(bsdName: String) throws -> (prefs: SCPreferences, service: SCNetworkService)? {
        try find(matching: { service in
            guard let interface = SCNetworkServiceGetInterface(service) else { return false }
            return (SCNetworkInterfaceGetBSDName(interface) as String?) == bsdName
        })
    }

    public static func find(serviceID: String) throws -> (prefs: SCPreferences, service: SCNetworkService)? {
        try find(matching: { service in
            self.serviceID(of: service) == serviceID
        })
    }

    public static func name(of service: SCNetworkService) -> String {
        (SCNetworkServiceGetName(service) as String?) ?? "-"
    }

    public static func serviceID(of service: SCNetworkService) -> String {
        (SCNetworkServiceGetServiceID(service) as String?) ?? "-"
    }

    public static func dnsConfiguration(of service: SCNetworkService) -> [String: Any]? {
        guard let proto = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeDNS) else { return nil }
        return SCNetworkProtocolGetConfiguration(proto) as? [String: Any]
    }

    static func openPrefs() throws -> SCPreferences {
        guard let prefs = SCPreferencesCreate(nil, "domicile" as CFString, nil) else {
            throw GatewayError.preferences(String(cString: SCErrorString(SCError())))
        }
        return prefs
    }

    private static func find(
        matching match: (SCNetworkService) -> Bool
    ) throws -> (prefs: SCPreferences, service: SCNetworkService)? {
        let prefs = try openPrefs()
        guard let set = SCNetworkSetCopyCurrent(prefs),
              let services = SCNetworkSetCopyServices(set) as? [SCNetworkService] else {
            throw GatewayError.preferences(String(localized: "no current network set", bundle: L10n.bundle))
        }
        for service in services where match(service) {
            return (prefs, service)
        }
        return nil
    }
}

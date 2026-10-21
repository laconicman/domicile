import Foundation
import Security

public enum APPassword {
    static func service(for ifname: String) -> String {
        "com.apple.network.wlan.swap.ssid.\(ifname)"
    }

    public static func exists(for ifname: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service(for: ifname),
            kSecAttrAccount as String: "AirPort",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        switch status {
        case errSecSuccess: return true
        case errSecItemNotFound: return false
        default: throw GatewayError.keychain(status)
        }
    }
}

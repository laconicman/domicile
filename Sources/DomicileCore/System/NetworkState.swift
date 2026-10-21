import Foundation
import SystemConfiguration

public enum NetworkState {
    private static func store() -> SCDynamicStore? {
        SCDynamicStoreCreate(nil, "domicile" as CFString, nil, nil)
    }

    private static func dict(_ key: String) -> [String: Any]? {
        guard let store = store(),
              let value = SCDynamicStoreCopyValue(store, key as CFString) else { return nil }
        return value as? [String: Any]
    }

    public static func linkActive(_ ifname: String) -> Bool {
        (dict("State:/Network/Interface/\(ifname)/Link")?["Active"] as? Bool) ?? false
    }

    public static func ipv4Addresses(_ ifname: String) -> [String] {
        dict("State:/Network/Interface/\(ifname)/IPv4")?["Addresses"] as? [String] ?? []
    }

    public static func globalDNSServers() -> [String] {
        dict("State:/Network/Global/DNS")?["ServerAddresses"] as? [String] ?? []
    }

    public static func primaryInterface() -> String? {
        dict("State:/Network/Global/IPv4")?["PrimaryInterface"] as? String
    }
}

public final class NetworkWatcher: @unchecked Sendable {
    private let hub: EventHub
    private var store: SCDynamicStore?
    private let queue = DispatchQueue(label: "com.learnable.domicile.network-watcher")

    public init(hub: EventHub) {
        self.hub = hub
    }

    public func start() {
        var context = SCDynamicStoreContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()
        let callback: SCDynamicStoreCallBack = { _, _, info in
            guard let info else { return }
            let watcher = Unmanaged<NetworkWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.hub.yield(.network)
        }
        guard let store = SCDynamicStoreCreate(nil, "domicile-watch" as CFString, callback, &context) else {
            Console.warn(String(localized: "could not create a dynamic store watcher; state changes will not be monitored", bundle: L10n.bundle))
            return
        }
        self.store = store
        let patterns = [
            "State:/Network/Interface/[^/]+/(Link|IPv4)",
            "State:/Network/Global/(IPv4|DNS)",
        ] as CFArray
        if !SCDynamicStoreSetNotificationKeys(store, nil, patterns) {
            Console.warn(String(localized: "could not register network notification patterns", bundle: L10n.bundle))
        }
        SCDynamicStoreSetDispatchQueue(store, queue)
    }

    public func stop() {
        if let store {
            SCDynamicStoreSetDispatchQueue(store, nil)
        }
        store = nil
    }
}

import CoreWLAN
import Foundation

public enum WiFiEvent: Sendable {
    case ssidChanged
    case linkChanged
    case powerChanged
}

public final class WiFi {
    private let interface: CWInterface

    public init(interfaceName: String?) throws {
        let client = CWWiFiClient.shared()
        let picked: CWInterface?
        if let interfaceName {
            picked = client.interface(withName: interfaceName)
        } else {
            picked = client.interface()
        }
        guard let picked else { throw GatewayError.noWiFi }
        interface = picked
    }

    public var name: String { interface.interfaceName ?? "en0" }
    public var powerOn: Bool { interface.powerOn() }
    public var serviceActive: Bool { interface.serviceActive() }

    public var mode: String {
        switch interface.interfaceMode() {
        case .none: return "none"
        case .station: return "station"
        case .IBSS: return "ibss"
        case .hostAP: return "hostAP"
        @unknown default: return "unknown"
        }
    }

    public func setPower(_ on: Bool) throws {
        try interface.setPower(on)
    }

    public func disassociate() {
        interface.disassociate()
    }
}

public final class WiFiEventBridge: NSObject, CWEventDelegate, @unchecked Sendable {
    private let hub: EventHub

    public init(hub: EventHub) {
        self.hub = hub
    }

    public func install() {
        let client = CWWiFiClient.shared()
        client.delegate = self
        for type: CWEventType in [.ssidDidChange, .linkDidChange, .powerDidChange] {
            do {
                try client.startMonitoringEvent(with: type)
            } catch {
                Console.warn(String(localized: "cannot monitor Wi-Fi event \(String(describing: type)): \(error.localizedDescription)", bundle: L10n.bundle))
            }
        }
    }

    public func uninstall() {
        let client = CWWiFiClient.shared()
        for type: CWEventType in [.ssidDidChange, .linkDidChange, .powerDidChange] {
            try? client.stopMonitoringEvent(with: type)
        }
        if client.delegate === self { client.delegate = nil }
    }

    public func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        hub.yield(.wifi(.ssidChanged))
    }

    public func linkDidChangeForWiFiInterface(withName interfaceName: String) {
        hub.yield(.wifi(.linkChanged))
    }

    public func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
        hub.yield(.wifi(.powerChanged))
    }
}

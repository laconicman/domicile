import Foundation
import Security

public enum GatewayError: Error, CustomStringConvertible, LocalizedError {
    case timeout(String)
    case interrupted(Int32)
    case notRoot
    case missingSnapshot
    case incompleteSnapshot
    case alreadyRunning(Int32)
    case uplinkDown(String)
    case noUplink
    case noWiFi
    case noService(String)
    case preferences(String)
    case keychain(OSStatus)
    case route(String)

    public var description: String {
        switch self {
        case .timeout(let what):
            return String(localized: "timed out waiting for: \(what)", bundle: L10n.bundle)
        case .interrupted(let signal):
            return String(localized: "interrupted by signal \(String(describing: signal))", bundle: L10n.bundle)
        case .notRoot:
            return String(localized: "this command needs root; run it with sudo", bundle: L10n.bundle)
        case .missingSnapshot:
            return String(localized: "no NAT snapshot at \(Paths.snapshotURL.path); enable Internet Sharing once in System Settings > General > Sharing, then run 'sudo domicile snapshot'", bundle: L10n.bundle)
        case .incompleteSnapshot:
            return String(localized: "the NAT configuration is incomplete; turn Internet Sharing on once in System Settings > General > Sharing, then run 'sudo domicile snapshot'", bundle: L10n.bundle)
        case .alreadyRunning(let pid):
            return String(localized: "already running (pid \(String(describing: pid))); use 'sudo domicile down'", bundle: L10n.bundle)
        case .uplinkDown(let name):
            return String(localized: "uplink \(name) has no link and no IPv4 after 25s; check the cable and enable Personal Hotspot on the iPhone, then run 'sudo domicile up' again", bundle: L10n.bundle)
        case .noUplink:
            return String(localized: "no uplink interface: pass --uplink or take a snapshot while Internet Sharing is on", bundle: L10n.bundle)
        case .noWiFi:
            return String(localized: "no Wi-Fi interface found", bundle: L10n.bundle)
        case .noService(let name):
            return String(localized: "no network service found for interface \(name)", bundle: L10n.bundle)
        case .preferences(let detail):
            return String(localized: "system preferences error: \(detail)", bundle: L10n.bundle)
        case .keychain(let status):
            let detail = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
            return String(localized: "keychain error: \(detail)", bundle: L10n.bundle)
        case .route(let detail):
            return String(localized: "route socket error: \(detail)", bundle: L10n.bundle)
        }
    }

    public var errorDescription: String? { description }
}

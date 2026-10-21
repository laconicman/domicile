import Foundation

public enum Event: Sendable {
    case network
    case wifi(WiFiEvent)
    case signal(Int32)
    case timeout(UInt64)
}

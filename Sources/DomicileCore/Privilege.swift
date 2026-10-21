import Foundation

public enum Privilege {
    public static var isRoot: Bool { geteuid() == 0 }

    public static func requireRoot() throws {
        guard isRoot else { throw GatewayError.notRoot }
    }
}

import Foundation
import SystemConfiguration

public struct DNSOverrideRecord: Codable, Sendable, Equatable {
    public var serviceID: String
    public var previousConfiguration: Data?

    public init(serviceID: String, previousConfiguration: Data?) {
        self.serviceID = serviceID
        self.previousConfiguration = previousConfiguration
    }
}

public enum DNSOverride {
    public static func apply(resolver: String, toInterface bsdName: String) throws -> DNSOverrideRecord {
        guard let (prefs, service) = try NetworkServices.find(bsdName: bsdName) else {
            throw GatewayError.noService(bsdName)
        }
        let proto = try dnsProtocol(of: service)
        let previous = SCNetworkProtocolGetConfiguration(proto) as? [String: Any]
        let previousData = try previous.flatMap {
            try PropertyListSerialization.data(fromPropertyList: $0, format: .binary, options: 0)
        }
        guard SCNetworkProtocolSetConfiguration(proto, ["ServerAddresses": [resolver]] as CFDictionary),
              SCPreferencesCommitChanges(prefs),
              SCPreferencesApplyChanges(prefs) else {
            throw GatewayError.preferences(String(cString: SCErrorString(SCError())))
        }
        return DNSOverrideRecord(
            serviceID: NetworkServices.serviceID(of: service),
            previousConfiguration: previousData
        )
    }

    public static func restore(_ record: DNSOverrideRecord) throws {
        guard let (prefs, service) = try NetworkServices.find(serviceID: record.serviceID) else {
            throw GatewayError.noService(record.serviceID)
        }
        let proto = try dnsProtocol(of: service)
        let previous = try record.previousConfiguration.flatMap {
            try PropertyListSerialization.propertyList(from: $0, format: nil)
        } as? [String: Any]
        guard SCNetworkProtocolSetConfiguration(proto, previous.map { $0 as CFDictionary }),
              SCPreferencesCommitChanges(prefs),
              SCPreferencesApplyChanges(prefs) else {
            throw GatewayError.preferences(String(cString: SCErrorString(SCError())))
        }
    }

    private static func dnsProtocol(of service: SCNetworkService) throws -> SCNetworkProtocol {
        if let proto = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeDNS) {
            return proto
        }
        guard SCNetworkServiceAddProtocolType(service, kSCNetworkProtocolTypeDNS),
              let proto = SCNetworkServiceCopyProtocol(service, kSCNetworkProtocolTypeDNS) else {
            throw GatewayError.preferences(String(cString: SCErrorString(SCError())))
        }
        return proto
    }
}

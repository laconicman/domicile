import Foundation
import DomicileCore
import Testing

@Suite("RunState")
struct RunStateTests {
    @Test func roundTripsWithDNSOverride() throws {
        let record = DNSOverrideRecord(
            serviceID: "AAAA-BBBB-CCCC",
            previousConfiguration: Data("plist".utf8)
        )
        let state = RunState(
            pid: 4242,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            uplink: "en6",
            wifiInterface: "en0",
            natEnabled: true,
            dnsOverride: record
        )
        let data = try JSONEncoder().encode(state)
        let back = try JSONDecoder().decode(RunState.self, from: data)
        #expect(back == state)
    }

    @Test func roundTripsWithNilDNSOverride() throws {
        let state = RunState(
            pid: 1,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000),
            uplink: "en7",
            wifiInterface: "en0",
            natEnabled: false,
            dnsOverride: nil
        )
        let data = try JSONEncoder().encode(state)
        let back = try JSONDecoder().decode(RunState.self, from: data)
        #expect(back == state)
        #expect(back.dnsOverride == nil)
    }
}

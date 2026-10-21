import DomicileCore
import Testing

private func makeFixture() -> [String: Any] {
    [
        "Enabled": 0,
        "SharingDevices": [String](),
        "PrimaryInterface": ["Device": "en6", "HardwareKey": "en6"],
        "AirPort": [
            "NetworkName": "TestNet",
            "NetworkPassword": "secret123",
            "Channel": 36,
        ],
    ]
}

@Suite("NATConfig")
struct NATConfigTests {
    @Test func completeFixturePasses() {
        #expect(NATConfig.isComplete(makeFixture()))
    }

    @Test func missingAirPortIsIncomplete() {
        var nat = makeFixture()
        nat.removeValue(forKey: "AirPort")
        #expect(!NATConfig.isComplete(nat))
    }

    @Test func missingPrimaryInterfaceIsIncomplete() {
        var nat = makeFixture()
        nat.removeValue(forKey: "PrimaryInterface")
        #expect(!NATConfig.isComplete(nat))
    }

    @Test func sanitizedRemovesOnlyThePassword() throws {
        let fixture = makeFixture()
        let clean = NATConfig.sanitized(fixture)
        let airport = try #require(clean["AirPort"] as? [String: Any])
        #expect(airport["NetworkPassword"] == nil)
        #expect(airport["NetworkName"] as? String == "TestNet")
        #expect(airport["Channel"] as? Int == 36)
        #expect((clean["PrimaryInterface"] as? [String: Any])?["Device"] as? String == "en6")
        let original = fixture["AirPort"] as? [String: Any]
        #expect(original?["NetworkPassword"] as? String == "secret123")
    }

    @Test func enabledSetsFlagAndDevices() {
        let on = NATConfig.enabled(makeFixture(), sharingDevices: ["en0"])
        #expect(on["Enabled"] as? Int == 1)
        #expect(on["SharingDevices"] as? [String] == ["en0"])
        #expect(NATConfig.isEnabled(on))
        let airport = on["AirPort"] as? [String: Any]
        #expect(airport?["NetworkPassword"] == nil)
    }

    @Test func disabledClearsFlagAndDevices() {
        var nat = makeFixture()
        nat["Enabled"] = 1
        nat["SharingDevices"] = ["en0"]
        let off = NATConfig.disabled(nat)
        #expect(off["Enabled"] as? Int == 0)
        #expect((off["SharingDevices"] as? [String] ?? []).isEmpty)
        #expect(!NATConfig.isEnabled(off))
    }

    @Test func primaryDeviceReadsDevice() {
        #expect(NATConfig.primaryDevice(makeFixture()) == "en6")
        #expect(NATConfig.primaryDevice([:]) == nil)
    }

    @Test func isEnabledAcceptsBool() {
        #expect(NATConfig.isEnabled(["Enabled": true]))
        #expect(!NATConfig.isEnabled(["Enabled": false]))
        #expect(!NATConfig.isEnabled([:]))
    }
}

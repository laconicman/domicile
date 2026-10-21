import DomicileCore
import Foundation
import Testing

@Suite("L10n")
struct L10nTests {
    @Test func englishStringsResourcePresent() {
        #expect(L10n.bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "en") != nil)
    }

    @Test func keyFallsBackToSourceText() {
        let text = String(localized: "timed out waiting for: \("x")", bundle: L10n.bundle)
        #expect(!text.isEmpty)
        #expect(text.contains("x"))
    }
}

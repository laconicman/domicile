import DomicileCore
import Foundation
import Testing

@Suite("L10n")
struct L10nTests {
    @Test func interpolatedKeyResolvesToPositionalValue() {
        let value = L10n.bundle.localizedString(forKey: "%@ IP %@%@", value: "MISSING", table: nil)
        #expect(value == "%1$@ IP %2$@%3$@")
    }

    @Test func keyFallsBackToSourceText() {
        let text = String(localized: "timed out waiting for: \("x")", bundle: L10n.bundle)
        #expect(!text.isEmpty)
        #expect(text.contains("x"))
    }
}

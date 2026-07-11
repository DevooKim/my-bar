import Testing
@testable import MyBar

struct SemanticVersionTests {
    @Test func parsesPlainAndPrefixed() {
        #expect(SemanticVersion("1.2.3") == SemanticVersion(major: 1, minor: 2, patch: 3))
        #expect(SemanticVersion("v0.10.0") == SemanticVersion(major: 0, minor: 10, patch: 0))
        #expect(SemanticVersion("2") == SemanticVersion(major: 2, minor: 0, patch: 0))
    }

    @Test func rejectsGarbage() {
        #expect(SemanticVersion("abc") == nil)
        #expect(SemanticVersion("1.2.3.4") == nil)
        #expect(SemanticVersion("1.-2") == nil)
    }

    @Test func ordersCorrectly() {
        #expect(SemanticVersion("1.2.3")! < SemanticVersion("1.10.0")!)
        #expect(SemanticVersion("0.9.9")! < SemanticVersion("1.0.0")!)
        #expect(!(SemanticVersion("1.0.0")! < SemanticVersion("1.0.0")!))
    }
}

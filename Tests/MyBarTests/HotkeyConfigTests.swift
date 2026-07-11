import Testing
import AppKit
@testable import MyBar

struct HotkeyConfigTests {
    @Test func carbonFlagsRoundtrip() {
        let flags: NSEvent.ModifierFlags = [.command, .shift]
        #expect(NSEvent.ModifierFlags(carbonFlags: flags.carbonFlags) == flags)
        let all: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        #expect(NSEvent.ModifierFlags(carbonFlags: all.carbonFlags) == all)
    }

    @Test func displayStringContainsModifierSymbols() {
        // ⇧⌘ + keyCode 42(backslash) — 정확한 키 글리프는 HotKey 라이브러리에
        // 의존하므로 수식키 기호만 검증한다.
        let cfg = HotkeyConfig(
            keyCode: 42,
            modifiers: NSEvent.ModifierFlags([.command, .shift]).carbonFlags
        )
        #expect(cfg.displayString.contains("\u{21E7}")) // ⇧
        #expect(cfg.displayString.contains("\u{2318}")) // ⌘
    }
}

import Testing
import Foundation
@testable import MyBar

@MainActor
struct PreferencesStoreTests {
    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "PreferencesStoreTests-\(UUID().uuidString)")!
    }

    @Test func defaults() {
        let store = PreferencesStore(defaults: freshDefaults())
        #expect(store.rehideSeconds == 10)
        #expect(!store.alwaysHiddenEnabled)
        #expect(store.iconStyle == .chevron)
        #expect(store.needsSetup)
        #expect(store.toggleHotkey == PreferencesStore.defaultHotkey)
    }

    @Test func persistsAcrossInstances() {
        let d = freshDefaults()
        let a = PreferencesStore(defaults: d)
        a.rehideSeconds = 30
        a.alwaysHiddenEnabled = true
        a.needsSetup = false
        a.iconStyle = .arrow
        let custom = HotkeyConfig(keyCode: 11, modifiers: 768)
        a.toggleHotkey = custom

        let b = PreferencesStore(defaults: d)
        #expect(b.rehideSeconds == 30)
        #expect(b.alwaysHiddenEnabled)
        #expect(!b.needsSetup)
        #expect(b.iconStyle == .arrow)
        #expect(b.toggleHotkey == custom)
    }

    @Test func removedHotkeyStaysRemoved() {
        // nil(사용자가 제거)과 "저장된 적 없음"(기본값 적용)을 구분해야 한다.
        let d = freshDefaults()
        let a = PreferencesStore(defaults: d)
        a.toggleHotkey = nil
        let b = PreferencesStore(defaults: d)
        #expect(b.toggleHotkey == nil)
    }
}

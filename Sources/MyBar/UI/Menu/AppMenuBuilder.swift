import AppKit

/// 메인 아이콘 우클릭 메뉴. 항목 구성·순서는 window-manager MenuBarContent를 따른다.
@MainActor
final class AppMenuBuilder: NSObject, NSMenuDelegate {
    private let engine: HidingEngine
    private let prefs: PreferencesStore
    private let app: AppState

    init(engine: HidingEngine, prefs: PreferencesStore, app: AppState) {
        self.engine = engine
        self.prefs = prefs
        self.app = app
    }

    func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        menu.addItem(item("My Bar 정보", action: #selector(openAbout)))
        menu.addItem(.separator())

        let toggleName = engine.state == .collapsed ? "숨긴 아이콘 보기" : "숨긴 아이콘 숨기기"
        menu.addItem(item(menuTitle(toggleName, hotkey: prefs.toggleHotkey), action: #selector(toggleHiding)))
        if prefs.alwaysHiddenEnabled {
            menu.addItem(item("항상 숨김 영역 보기", action: #selector(showAll)))
        }
        menu.addItem(.separator())

        menu.addItem(item("업데이트 확인...", action: #selector(checkUpdates)))

        let settings = item("설정...", action: #selector(openSettings))
        settings.keyEquivalent = ","
        settings.keyEquivalentModifierMask = .command
        settings.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        menu.addItem(settings)

        let quit = item("종료", action: #selector(quit))
        quit.keyEquivalent = "q"
        quit.keyEquivalentModifierMask = .command
        quit.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(quit)

        return menu
    }

    private func item(_ title: String, action: Selector) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: "")
        i.target = self
        return i
    }

    /// window-manager와 동일한 "이름   단축키" 표기.
    private func menuTitle(_ name: String, hotkey: HotkeyConfig?) -> String {
        if let h = hotkey { return "\(name)   \(h.displayString)" }
        return name
    }

    // 메뉴가 열려 있는 동안 자동 재숨김을 보류한다.
    func menuWillOpen(_ menu: NSMenu) { engine.isHoldingRehide = true }
    func menuDidClose(_ menu: NSMenu) { engine.isHoldingRehide = false }

    @objc private func openAbout() { app.openAbout() }
    @objc private func toggleHiding() { engine.handle(.toggle) }
    @objc private func showAll() { engine.handle(.toggleFull) }
    @objc private func checkUpdates() { Updater.checkForUpdates(silent: false) }
    @objc private func openSettings() { app.openSettings(.general) }
    @objc private func quit() { NSApp.terminate(nil) }
}

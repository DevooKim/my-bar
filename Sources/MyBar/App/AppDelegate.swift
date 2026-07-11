import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var prefs: PreferencesStore!
    private(set) var engine: HidingEngine!
    private(set) var hotkeys: HotkeyManager!
    private(set) var app: AppState!
    private(set) var statusBar: StatusBarController!
    private var menuBuilder: AppMenuBuilder!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        prefs = PreferencesStore()

        engine = HidingEngine()
        engine.alwaysHiddenEnabled = { [weak self] in self?.prefs.alwaysHiddenEnabled ?? false }
        engine.rehideDelay = { [weak self] in self?.prefs.rehideSeconds ?? 0 }

        hotkeys = HotkeyManager()
        let updatePrompt = UpdatePromptState()
        app = AppState(prefs: prefs, engine: engine, hotkeys: hotkeys, updatePrompt: updatePrompt)

        statusBar = StatusBarController(engine: engine, prefs: prefs)
        menuBuilder = AppMenuBuilder(engine: engine, prefs: prefs, app: app)
        statusBar.menuProvider = { [weak self] in self?.menuBuilder.makeMenu() ?? NSMenu() }

        hotkeys.onToggle = { [weak self] in self?.engine.handle(.toggle) }
        hotkeys.rebuild(config: prefs.toggleHotkey)
        prefs.$toggleHotkey
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] config in self?.hotkeys.rebuild(config: config) }
            .store(in: &cancellables)

        Updater.promptState = updatePrompt
        Updater.openWindow = { [weak self] in self?.app.openUpdateWindow() }

        if prefs.needsSetup {
            // 펼친 상태로 시작해 온보딩 안내대로 바로 ⌘드래그해 볼 수 있게 한다.
            engine.handle(.toggle)
            app.openOnboarding()
        }

        // Check for updates shortly after launch, then every 24h while running.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            Updater.startAutomaticChecks()
        }
    }

    /// 이미 실행 중인 앱을 다시 열면(Finder/`open`) 설정 창을 띄운다.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        app.openSettings(.general)
        return true
    }

}

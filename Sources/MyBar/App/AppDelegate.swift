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
    private var outsideClickMonitor: Any?
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

        installOutsideClickMonitor()

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

    // MARK: 외부 클릭 시 재숨김

    private func installOutsideClickMonitor() {
        // 글로벌 모니터는 다른 앱의 이벤트만 받는다 (자기 앱 메뉴 클릭은 제외).
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { _ in
            Task { @MainActor [weak self] in self?.handleOutsideClick() }
        }
    }

    private func handleOutsideClick() {
        guard prefs.rehideOnOutsideClick, engine.state != .collapsed else { return }
        // 메뉴바 안 클릭은 숨겼던 아이콘을 쓰는 중일 수 있으니 타이머에 맡긴다.
        let inMenuBar = Self.isInMenuBarBand(
            NSEvent.mouseLocation,
            screenFrames: NSScreen.screens.map(\.frame),
            menuBarThickness: NSStatusBar.system.thickness
        )
        guard !inMenuBar else { return }
        engine.handle(.collapse)
    }

    /// 좌표가 어느 화면의 메뉴바 밴드(상단 thickness 높이) 안인지 판정한다.
    /// 상·하한을 모두 검사해야 한다 — 하한만 보면 위쪽에 배치된 다른 화면의
    /// 모든 클릭이 아래 화면의 "메뉴바"로 오분류된다 (상하 멀티 모니터 버그).
    nonisolated static func isInMenuBarBand(_ location: CGPoint, screenFrames: [CGRect], menuBarThickness: CGFloat) -> Bool {
        screenFrames.contains { f in
            location.x >= f.minX && location.x <= f.maxX
                && location.y <= f.maxY + 1
                && location.y >= f.maxY - menuBarThickness - 1
        }
    }
}

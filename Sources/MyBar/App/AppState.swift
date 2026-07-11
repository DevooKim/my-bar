import SwiftUI
import AppKit

/// 설정·정보·업데이트·온보딩 창을 NSWindow + NSHostingController로 소유한다.
/// (window-manager의 openWindow 주입 패턴은 항상 렌더되는 MenuBarExtra label이
/// 필요해 이 앱에선 쓸 수 없다 — 스펙 §7.)
@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: SettingsTab = .general

    let prefs: PreferencesStore
    let engine: HidingEngine
    let hotkeys: HotkeyManager
    let updatePrompt: UpdatePromptState

    private var settingsWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var updateWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var updateCloseDelegate: UpdateWindowCloseDelegate?

    init(prefs: PreferencesStore, engine: HidingEngine, hotkeys: HotkeyManager, updatePrompt: UpdatePromptState) {
        self.prefs = prefs
        self.engine = engine
        self.hotkeys = hotkeys
        self.updatePrompt = updatePrompt
    }

    func openSettings(_ tab: SettingsTab = .general) {
        selectedTab = tab
        if settingsWindow == nil {
            let root = SettingsRootView()
                .environmentObject(self)
                .environmentObject(prefs)
                .environmentObject(hotkeys)
            settingsWindow = makeWindow(root, title: "My Bar",
                                        size: NSSize(width: 640, height: 480), resizable: true)
        }
        present(settingsWindow)
    }

    func openAbout() {
        if aboutWindow == nil {
            let root = InfoView().frame(width: 320)
            aboutWindow = makeWindow(root, title: "My Bar 정보")
        }
        present(aboutWindow)
    }

    /// Updater.openWindow로 주입 — 프롬프트가 설정된 뒤 호출된다.
    func openUpdateWindow() {
        if updateWindow == nil {
            let root = UpdateWindowRoot(dismiss: { [weak self] in self?.updateWindow?.close() })
                .environmentObject(updatePrompt)
            let window = makeWindow(root, title: "")
            // 사용자가 창을 그냥 닫으면 대기 중인 프롬프트를 dismiss로 해결한다.
            let delegate = UpdateWindowCloseDelegate(state: updatePrompt)
            window.delegate = delegate
            updateCloseDelegate = delegate
            updateWindow = window
        }
        present(updateWindow)
    }

    func openOnboarding() {
        if onboardingWindow == nil {
            let root = OnboardingView(onDone: { [weak self] in self?.onboardingWindow?.close() })
                .environmentObject(prefs)
            onboardingWindow = makeWindow(root, title: "시작하기")
        }
        present(onboardingWindow)
    }

    private func present(_ window: NSWindow?) {
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindow<V: View>(_ root: V, title: String,
                                     size: NSSize? = nil, resizable: Bool = false) -> NSWindow {
        let host = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: host)
        window.title = title
        var style: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView]
        if resizable {
            style.insert(.resizable)
            style.insert(.miniaturizable)
        }
        window.styleMask = style
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false
        if let size { window.setContentSize(size) }
        window.center()
        return window
    }
}

/// 업데이트 창이 닫힐 때 대기 중인 continuation을 dismiss로 풀어준다.
@MainActor
final class UpdateWindowCloseDelegate: NSObject, NSWindowDelegate {
    private let state: UpdatePromptState
    init(state: UpdatePromptState) { self.state = state }
    func windowWillClose(_ notification: Notification) {
        state.resolve(.dismiss)
    }
}

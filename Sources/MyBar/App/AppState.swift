import SwiftUI
import AppKit

/// 설정·정보·업데이트 창은 SwiftUI Window scene(.hiddenTitleBar)이 소유한다 —
/// AppKit 컨텍스트에서는 EnvironmentValues().openWindow(id:)로 연다 (스펙 §7).
/// 온보딩 창만 예외적으로 NSWindow + NSHostingController를 직접 소유한다.
@MainActor
final class AppState: ObservableObject {
    static let settingsWindowID = "settings"
    static let aboutWindowID = "about"

    @Published var selectedTab: SettingsTab = .general

    let prefs: PreferencesStore
    let engine: HidingEngine
    let hotkeys: HotkeyManager
    let updatePrompt: UpdatePromptState

    private var onboardingWindow: NSWindow?

    init(prefs: PreferencesStore, engine: HidingEngine, hotkeys: HotkeyManager, updatePrompt: UpdatePromptState) {
        self.prefs = prefs
        self.engine = engine
        self.hotkeys = hotkeys
        self.updatePrompt = updatePrompt
    }

    func openSettings(_ tab: SettingsTab = .general) {
        selectedTab = tab
        // 스파이크 검증됨: SwiftUI 앱 라이프사이클에서는 EnvironmentValues()로
        // 얻은 openWindow 액션이 AppKit 컨텍스트에서도 해당 scene을 연다.
        EnvironmentValues().openWindow(id: Self.settingsWindowID)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openAbout() {
        EnvironmentValues().openWindow(id: Self.aboutWindowID)
        NSApp.activate(ignoringOtherApps: true)
    }

    func openUpdateWindow() {
        EnvironmentValues().openWindow(id: UpdatePromptState.windowID)
        NSApp.activate(ignoringOtherApps: true)
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

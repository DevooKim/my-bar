import SwiftUI

@main
struct MyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // 설정 창은 SwiftUI가 직접 소유하는 Window scene으로 연다 — 수동
        // NSWindow에 욱여넣으면 SwiftUI가 윈도우 통합을 못 잡아 사이드바
        // 머티리얼이 타이틀바(신호등) 영역까지 채워지지 않는다 (WM과 동일 이유).
        // LSUIElement라도 Window scene은 실행 시 자동 표시되므로 suppressed로 억제.
        Window("My Bar", id: AppState.settingsWindowID) {
            SettingsRootView()
                .environmentObject(delegate.app)
                .environmentObject(delegate.prefs)
                .environmentObject(delegate.hotkeys)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 640, height: 480)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // 정보 창(메뉴바 "My Bar 정보"). 표준 About 패널 대신 InfoView —
        // GitHub 링크가 실제로 클릭되게 (WM과 동일).
        Window("My Bar 정보", id: AppState.aboutWindowID) {
            InfoView()
                .frame(width: 320)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)

        // 업데이트 알림 창. Updater가 UpdatePromptState에 프롬프트를 설정한 뒤
        // openUpdateWindow로 이 창을 연다 (WM과 동일).
        Window("", id: UpdatePromptState.windowID) {
            UpdateWindowRoot()
                .environmentObject(delegate.updatePrompt)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .defaultLaunchBehavior(.suppressed)
        .restorationBehavior(.disabled)
    }
}

import SwiftUI

@main
struct MyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // 메뉴바 전용 앱 — 창은 AppState가 NSWindow로 직접 연다 (스펙 §7).
        Settings { EmptyView() }
    }
}

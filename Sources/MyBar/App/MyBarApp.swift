import SwiftUI

@main
struct MyBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // 메뉴바 전용 앱 — 창은 AppState가 NSWindow로 직접 연다 (스펙 §7).
        // Settings scene은 SwiftUI App 프로토콜을 만족시키기 위한 비활성 placeholder.
        Settings { EmptyView() }
    }
}

// Task 12에서 상태바·엔진·업데이터를 조립한다.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {}

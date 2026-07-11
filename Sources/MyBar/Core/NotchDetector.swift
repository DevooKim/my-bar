import AppKit

enum NotchDetector {
    /// 연결된 화면 중 노치가 있는 화면이 하나라도 있으면 true.
    @MainActor
    static var hasNotch: Bool {
        NSScreen.screens.contains { $0.safeAreaInsets.top > 0 }
    }
}

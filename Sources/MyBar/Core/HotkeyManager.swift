import Foundation
import HotKey

/// 토글 글로벌 단축키 1개를 관리한다. 설정 변경 시 rebuild로 재등록.
@MainActor
final class HotkeyManager: ObservableObject {
    private var hotKey: HotKey?

    /// 단축키가 눌리면 호출 (AppDelegate가 engine.handle(.toggle)로 연결).
    var onToggle: (() -> Void)?

    /// HotkeyCaptureView가 캡처 중일 때 기존 단축키가 반응하지 않게 일시정지.
    func setPaused(_ paused: Bool) {
        hotKey?.isPaused = paused
    }

    func rebuild(config: HotkeyConfig?) {
        hotKey = nil
        guard let config, let combo = config.hotKey else { return }
        let hk = HotKey(key: combo.key, modifiers: combo.mods)
        hk.keyDownHandler = { [weak self] in self?.onToggle?() }
        hotKey = hk
    }
}

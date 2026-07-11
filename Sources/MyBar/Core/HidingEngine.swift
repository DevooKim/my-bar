import Foundation

/// 숨김 상태의 소유자. 전이는 HidingState.next에 위임하고,
/// 펼친 상태에서 자동 재숨김 타이머를 관리한다.
@MainActor
final class HidingEngine {
    private(set) var state: HidingState = .collapsed

    /// PreferencesStore에서 주입 (엔진은 스토어를 모른다 — 테스트 용이).
    var alwaysHiddenEnabled: () -> Bool = { false }
    /// 자동 재숨김까지의 초. 0 = 자동 재숨김 없음.
    var rehideDelay: () -> TimeInterval = { 0 }
    /// 상태가 바뀔 때마다 새 상태와 함께 호출 (StatusBarController가 구독).
    var onChange: ((HidingState) -> Void)?

    /// 메뉴가 열려 있는 동안 등 재숨김을 보류. 풀리면 타이머 재시작.
    var isHoldingRehide = false {
        didSet {
            if isHoldingRehide {
                cancelRehide()
            } else {
                scheduleRehideIfNeeded()
            }
        }
    }

    private var rehideTimer: Timer?
    var rehideTimerActive: Bool { rehideTimer != nil }

    func handle(_ event: HidingState.Event) {
        let new = state.next(event, alwaysHiddenEnabled: alwaysHiddenEnabled())
        guard new != state else { return }
        state = new
        cancelRehide()
        scheduleRehideIfNeeded()
        onChange?(new)
    }

    private func scheduleRehideIfNeeded() {
        guard state != .collapsed, !isHoldingRehide else { return }
        let delay = rehideDelay()
        guard delay > 0 else { return }
        let timer = Timer(timeInterval: delay, repeats: false) { _ in
            Task { @MainActor [weak self] in self?.handle(.rehideTimerFired) }
        }
        RunLoop.main.add(timer, forMode: .common)
        rehideTimer = timer
    }

    private func cancelRehide() {
        rehideTimer?.invalidate()
        rehideTimer = nil
    }
}

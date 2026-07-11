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

    /// 재숨김 시점에 사용자가 메뉴바를 조작 중이면(⌘드래그 등) 접기를 미룬다.
    /// AppDelegate가 주입 (엔진은 AppKit을 모른다 — 테스트 용이).
    var shouldDeferRehide: () -> Bool = { false }
    /// 미뤘을 때 다시 확인하기까지의 간격(초).
    var deferRecheckInterval: TimeInterval = 2

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

    /// 재숨김 타이머 만료. 사용자가 메뉴바 조작 중이면 잠시 뒤 재확인한다.
    func rehideTimerDidFire() {
        rehideTimer = nil
        if shouldDeferRehide() {
            scheduleRehide(after: deferRecheckInterval)
            return
        }
        handle(.rehideTimerFired)
    }

    private func scheduleRehideIfNeeded() {
        guard state != .collapsed, !isHoldingRehide else { return }
        let delay = rehideDelay()
        guard delay > 0 else { return }
        scheduleRehide(after: delay)
    }

    private func scheduleRehide(after delay: TimeInterval) {
        guard state != .collapsed, !isHoldingRehide else { return }
        cancelRehide()
        let timer = Timer(timeInterval: delay, repeats: false) { _ in
            Task { @MainActor [weak self] in self?.rehideTimerDidFire() }
        }
        RunLoop.main.add(timer, forMode: .common)
        rehideTimer = timer
    }

    private func cancelRehide() {
        rehideTimer?.invalidate()
        rehideTimer = nil
    }
}

import Foundation

/// 메뉴바 숨김 상태. collapsed = 숨김 영역이 밀려나 안 보임,
/// expanded = 숨김 영역 표시, fullyExpanded = 항상 숨김 영역까지 표시.
enum HidingState: Equatable, CaseIterable {
    case collapsed
    case expanded
    case fullyExpanded

    enum Event {
        case toggle          // 메인 아이콘 클릭 / 글로벌 단축키
        case toggleFull      // ⌥+클릭 / 메뉴 "항상 숨김 영역 보기"
        case rehideTimerFired
        case collapse        // 외부 클릭 등 강제 접기
    }

    /// 순수 전이 함수 — AppKit 비의존, 단위 테스트 대상.
    func next(_ event: Event, alwaysHiddenEnabled: Bool) -> HidingState {
        switch event {
        case .toggle:
            return self == .collapsed ? .expanded : .collapsed
        case .toggleFull:
            guard alwaysHiddenEnabled else {
                return self == .collapsed ? .expanded : .collapsed
            }
            return self == .fullyExpanded ? .collapsed : .fullyExpanded
        case .rehideTimerFired, .collapse:
            return .collapsed
        }
    }
}

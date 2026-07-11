import Testing
@testable import MyBar

struct HidingStateTests {
    @Test func toggleCyclesCollapsedExpanded() {
        #expect(HidingState.collapsed.next(.toggle, alwaysHiddenEnabled: false) == .expanded)
        #expect(HidingState.expanded.next(.toggle, alwaysHiddenEnabled: false) == .collapsed)
        // fullyExpanded에서 일반 토글은 접기
        #expect(HidingState.fullyExpanded.next(.toggle, alwaysHiddenEnabled: true) == .collapsed)
    }

    @Test func toggleFullWhenEnabled() {
        #expect(HidingState.collapsed.next(.toggleFull, alwaysHiddenEnabled: true) == .fullyExpanded)
        #expect(HidingState.expanded.next(.toggleFull, alwaysHiddenEnabled: true) == .fullyExpanded)
        #expect(HidingState.fullyExpanded.next(.toggleFull, alwaysHiddenEnabled: true) == .collapsed)
    }

    @Test func toggleFullWhenDisabledActsAsToggle() {
        #expect(HidingState.collapsed.next(.toggleFull, alwaysHiddenEnabled: false) == .expanded)
        #expect(HidingState.expanded.next(.toggleFull, alwaysHiddenEnabled: false) == .collapsed)
    }

    @Test func timerAndCollapseAlwaysCollapse() {
        for state in [HidingState.collapsed, .expanded, .fullyExpanded] {
            #expect(state.next(.rehideTimerFired, alwaysHiddenEnabled: true) == .collapsed)
            #expect(state.next(.collapse, alwaysHiddenEnabled: true) == .collapsed)
        }
    }
}

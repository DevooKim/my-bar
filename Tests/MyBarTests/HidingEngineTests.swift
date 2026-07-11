import Testing
@testable import MyBar

@MainActor
struct HidingEngineTests {
    private func makeEngine(delay: Double = 10, alwaysHidden: Bool = false) -> HidingEngine {
        let e = HidingEngine()
        e.rehideDelay = { delay }
        e.alwaysHiddenEnabled = { alwaysHidden }
        return e
    }

    @Test func toggleExpandsAndSchedulesRehide() {
        let e = makeEngine(delay: 10)
        e.handle(.toggle)
        #expect(e.state == .expanded)
        #expect(e.rehideTimerActive)
    }

    @Test func zeroDelayDisablesRehide() {
        let e = makeEngine(delay: 0)
        e.handle(.toggle)
        #expect(e.state == .expanded)
        #expect(!e.rehideTimerActive)
    }

    @Test func collapseCancelsTimer() {
        let e = makeEngine(delay: 10)
        e.handle(.toggle)
        e.handle(.collapse)
        #expect(e.state == .collapsed)
        #expect(!e.rehideTimerActive)
    }

    @Test func holdSuppressesAndResumeReschedules() {
        let e = makeEngine(delay: 10)
        e.handle(.toggle)
        e.isHoldingRehide = true
        #expect(!e.rehideTimerActive)
        e.isHoldingRehide = false
        #expect(e.rehideTimerActive)
    }

    @Test func timerEventCollapses() {
        let e = makeEngine(delay: 10)
        e.handle(.toggle)
        e.handle(.rehideTimerFired)
        #expect(e.state == .collapsed)
        #expect(!e.rehideTimerActive)
    }

    @Test func onChangeFiresWithNewState() {
        let e = makeEngine()
        var seen: [HidingState] = []
        e.onChange = { seen.append($0) }
        e.handle(.toggle)
        e.handle(.toggle)
        #expect(seen == [.expanded, .collapsed])
    }
}

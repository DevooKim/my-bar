import Testing
@testable import MyBar

struct StatusBarOrderTests {
    @Test func validWhenMainRightOfSeparator() {
        #expect(StatusBarController.isOrderValid(mainX: 300, separatorX: 200, alwaysHiddenX: nil))
        #expect(StatusBarController.isOrderValid(mainX: 300, separatorX: 200, alwaysHiddenX: 100))
    }

    @Test func invalidWhenSeparatorRightOfMain() {
        #expect(!StatusBarController.isOrderValid(mainX: 200, separatorX: 300, alwaysHiddenX: nil))
    }

    @Test func invalidWhenAlwaysHiddenRightOfSeparator() {
        #expect(!StatusBarController.isOrderValid(mainX: 300, separatorX: 200, alwaysHiddenX: 250))
    }
}

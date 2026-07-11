import Foundation
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

    // 상하 배치 멀티 모니터 지오메트리 — 상한 없이 하한만 검사하면
    // 위 화면 본문이 아래 화면의 메뉴바 밴드로 오분류된다.
    private static let stackedScreens = [
        CGRect(x: 0, y: 0, width: 1800, height: 1169),
        CGRect(x: 300, y: -900, width: 1440, height: 900),
    ]

    @Test func menuBarBandDetectsBandsOnly() {
        #expect(!StatusBarController.isInMenuBarBand(CGPoint(x: 1659, y: 816), screenFrames: Self.stackedScreens, menuBarThickness: 24))
        #expect(StatusBarController.isInMenuBarBand(CGPoint(x: 900, y: 1160), screenFrames: Self.stackedScreens, menuBarThickness: 24))
        #expect(StatusBarController.isInMenuBarBand(CGPoint(x: 900, y: -10), screenFrames: Self.stackedScreens, menuBarThickness: 24))
        #expect(!StatusBarController.isInMenuBarBand(CGPoint(x: 1060, y: -749), screenFrames: Self.stackedScreens, menuBarThickness: 24))
    }
}

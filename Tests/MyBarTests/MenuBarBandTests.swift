import Testing
import Foundation
@testable import MyBar

struct MenuBarBandTests {
    // 위(주) 화면 + 아래 보조 화면의 상하 배치 — 실제 버그 재현 지오메트리.
    private let screens = [
        CGRect(x: 0, y: 0, width: 1800, height: 1169),
        CGRect(x: 300, y: -900, width: 1440, height: 900),
    ]

    @Test func upperScreenBodyClickIsNotMenuBar() {
        // 회귀: 위 화면 본문 클릭이 아래 화면의 메뉴바 밴드(상한 없음)로
        // 오분류되어 외부 클릭 재숨김이 스킵되던 버그.
        #expect(!AppDelegate.isInMenuBarBand(CGPoint(x: 1659, y: 816), screenFrames: screens, menuBarThickness: 24))
    }

    @Test func upperScreenMenuBarClickIsMenuBar() {
        #expect(AppDelegate.isInMenuBarBand(CGPoint(x: 900, y: 1160), screenFrames: screens, menuBarThickness: 24))
    }

    @Test func lowerScreenMenuBarClickIsMenuBar() {
        #expect(AppDelegate.isInMenuBarBand(CGPoint(x: 900, y: -10), screenFrames: screens, menuBarThickness: 24))
    }

    @Test func lowerScreenBodyClickIsNotMenuBar() {
        #expect(!AppDelegate.isInMenuBarBand(CGPoint(x: 1060, y: -749), screenFrames: screens, menuBarThickness: 24))
    }
}

import AppKit
import Combine

/// NSStatusItem 3개(메인·구분자·항상숨김 구분자)를 소유하고, HidingEngine
/// 상태에 따라 구분자 길이를 조절해 왼쪽 아이콘들을 화면 밖으로 밀어낸다.
@MainActor
final class StatusBarController {
    /// 접힘 상태에서 구분자에 줄 길이 — 왼쪽 아이템 전부를 밀어낸다.
    static let hiddenLength: CGFloat = 10000
    static let separatorLength: CGFloat = 12

    static let mainAutosave = "mybar.main"
    static let separatorAutosave = "mybar.separator"
    static let alwaysHiddenAutosave = "mybar.alwaysHidden"

    private let bar = NSStatusBar.system
    private var mainItem: NSStatusItem!
    private var separatorItem: NSStatusItem!
    private var alwaysHiddenItem: NSStatusItem?

    let engine: HidingEngine
    private let prefs: PreferencesStore
    /// 우클릭 시 보여줄 메뉴 (AppDelegate가 AppMenuBuilder를 연결).
    var menuProvider: (() -> NSMenu)?

    private var cancellables = Set<AnyCancellable>()

    init(engine: HidingEngine, prefs: PreferencesStore) {
        self.engine = engine
        self.prefs = prefs

        createItems()
        engine.onChange = { [weak self] _ in self?.apply() }
        apply()

        prefs.$alwaysHiddenEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in self?.alwaysHiddenChanged(enabled) }
            .store(in: &cancellables)
        prefs.$iconStyle
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.apply() }
            .store(in: &cancellables)
    }

    /// 생성 순서 = 오른쪽부터. 새 아이템은 기존 아이템 왼쪽에 붙으므로
    /// main → separator → alwaysHidden 순으로 만들면 기본 배치가 나온다.
    /// (autosave 위치가 저장돼 있으면 시스템이 그 위치를 우선한다.)
    private func createItems() {
        mainItem = bar.statusItem(withLength: NSStatusItem.squareLength)
        mainItem.autosaveName = Self.mainAutosave
        if let button = mainItem.button {
            button.target = self
            button.action = #selector(mainClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        separatorItem = bar.statusItem(withLength: Self.separatorLength)
        separatorItem.autosaveName = Self.separatorAutosave
        separatorItem.button?.title = "|"
        separatorItem.button?.appearsDisabled = true

        if prefs.alwaysHiddenEnabled {
            createAlwaysHiddenItem()
        }
    }

    private func createAlwaysHiddenItem() {
        let item = bar.statusItem(withLength: Self.hiddenLength)
        item.autosaveName = Self.alwaysHiddenAutosave
        item.button?.title = "⋮"
        item.button?.appearsDisabled = true
        alwaysHiddenItem = item
    }

    private func alwaysHiddenChanged(_ enabled: Bool) {
        if enabled {
            if alwaysHiddenItem == nil { createAlwaysHiddenItem() }
        } else {
            if let item = alwaysHiddenItem { bar.removeStatusItem(item) }
            alwaysHiddenItem = nil
            if engine.state == .fullyExpanded { engine.handle(.collapse) }
        }
        apply()
    }

    /// 현재 상태를 아이템 길이·아이콘에 반영한다.
    private func apply() {
        let state = engine.state
        mainItem.button?.image = NSImage(
            systemSymbolName: prefs.iconStyle.symbol(for: state),
            accessibilityDescription: "My Bar"
        )
        separatorItem.length = state == .collapsed ? Self.hiddenLength : Self.separatorLength
        alwaysHiddenItem?.length = state == .fullyExpanded ? Self.separatorLength : Self.hiddenLength
    }

    // MARK: 클릭 라우팅

    @objc private func mainClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showMenu()
            return
        }
        if event.modifierFlags.contains(.option) {
            engine.handle(.toggleFull)
        } else {
            engine.handle(.toggle)
        }
        if engine.state != .collapsed {
            // 펼침 직후 시스템 재배치가 끝난 뒤 순서를 검증한다.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.validateOrderAndRepairIfNeeded()
            }
        }
    }

    /// 우클릭: 메뉴를 일시적으로 붙여 표시한다. menu를 계속 물려두면
    /// 좌클릭도 메뉴를 열어 버리므로 표시 후 바로 떼어낸다.
    private func showMenu() {
        guard let menu = menuProvider?() else { return }
        mainItem.menu = menu
        mainItem.button?.performClick(nil)
        mainItem.menu = nil
    }

    // MARK: 순서 검증·복구

    /// 화면 x좌표 기준 main > separator > alwaysHidden 이어야 정상.
    nonisolated static func isOrderValid(mainX: CGFloat, separatorX: CGFloat, alwaysHiddenX: CGFloat?) -> Bool {
        guard mainX > separatorX else { return false }
        if let ax = alwaysHiddenX { return separatorX > ax }
        return true
    }

    func validateOrderAndRepairIfNeeded() {
        // 접힘 상태에선 구분자가 화면 밖이라 좌표가 의미 없다.
        guard engine.state != .collapsed else { return }
        guard let mainX = mainItem.button?.window?.frame.origin.x,
              let sepX = separatorItem.button?.window?.frame.origin.x else { return }
        let alwaysX = alwaysHiddenItem?.button?.window?.frame.origin.x
        guard !Self.isOrderValid(mainX: mainX, separatorX: sepX, alwaysHiddenX: alwaysX) else { return }
        repairOrder()
    }

    /// autosave된 위치를 지우고 아이템을 재생성해 기본 순서로 복구한다.
    private func repairOrder() {
        for name in [Self.mainAutosave, Self.separatorAutosave, Self.alwaysHiddenAutosave] {
            UserDefaults.standard.removeObject(forKey: "NSStatusItem Preferred Position \(name)")
        }
        bar.removeStatusItem(mainItem)
        bar.removeStatusItem(separatorItem)
        if let item = alwaysHiddenItem { bar.removeStatusItem(item) }
        alwaysHiddenItem = nil
        createItems()
        apply()

        let alert = NSAlert()
        alert.messageText = "메뉴바 아이콘 순서 초기화"
        alert.informativeText = "구분자가 메인 아이콘 오른쪽으로 이동해 있어 위치를 초기화했습니다. ⌘를 누른 채 드래그해 다시 정리해 주세요."
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}

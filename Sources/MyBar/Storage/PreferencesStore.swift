import Foundation
import Combine
import Carbon.HIToolbox

/// 메뉴바 메인 아이콘 모양. 상태(접힘/펼침)에 따라 심볼이 바뀐다.
enum MenuIconStyle: String, CaseIterable, Identifiable {
    case chevron
    case arrow

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chevron: return "화살괄호 (❮ ❯)"
        case .arrow: return "화살표 (⇤ ⇥)"
        }
    }

    /// collapsed = "클릭하면 왼쪽에서 펼쳐진다"는 의미로 왼쪽 방향.
    func symbol(for state: HidingState) -> String {
        switch self {
        case .chevron:
            return state == .collapsed ? "chevron.backward" : "chevron.forward"
        case .arrow:
            return state == .collapsed ? "arrow.left.to.line" : "arrow.right.to.line"
        }
    }
}

/// 사용자 설정. UserDefaults가 원천이며 didSet에서 즉시 저장한다.
@MainActor
final class PreferencesStore: ObservableObject {
    private let defaults: UserDefaults

    private enum Key {
        static let rehideSeconds = "rehideSeconds"
        static let alwaysHiddenEnabled = "alwaysHiddenEnabled"
        static let toggleHotkey = "toggleHotkey"
        static let iconStyle = "iconStyle"
        static let needsSetup = "needsSetup"
    }

    /// 기본 토글 단축키 ⇧⌘\ .
    static let defaultHotkey = HotkeyConfig(
        keyCode: UInt32(kVK_ANSI_Backslash),
        modifiers: UInt32(cmdKey | shiftKey)
    )

    @Published var rehideSeconds: Double {
        didSet { defaults.set(rehideSeconds, forKey: Key.rehideSeconds) }
    }
    @Published var alwaysHiddenEnabled: Bool {
        didSet { defaults.set(alwaysHiddenEnabled, forKey: Key.alwaysHiddenEnabled) }
    }
    @Published var iconStyle: MenuIconStyle {
        didSet { defaults.set(iconStyle.rawValue, forKey: Key.iconStyle) }
    }
    @Published var needsSetup: Bool {
        didSet { defaults.set(needsSetup, forKey: Key.needsSetup) }
    }
    /// nil = 사용자가 단축키를 제거함 (빈 Data로 저장해 기본값과 구분).
    @Published var toggleHotkey: HotkeyConfig? {
        didSet {
            if let hotkey = toggleHotkey, let data = try? JSONEncoder().encode(hotkey) {
                defaults.set(data, forKey: Key.toggleHotkey)
            } else {
                defaults.set(Data(), forKey: Key.toggleHotkey)
            }
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.rehideSeconds: 10.0,
            Key.alwaysHiddenEnabled: false,
            Key.iconStyle: MenuIconStyle.chevron.rawValue,
            Key.needsSetup: true,
        ])
        rehideSeconds = defaults.double(forKey: Key.rehideSeconds)
        alwaysHiddenEnabled = defaults.bool(forKey: Key.alwaysHiddenEnabled)
        iconStyle = MenuIconStyle(rawValue: defaults.string(forKey: Key.iconStyle) ?? "") ?? .chevron
        needsSetup = defaults.bool(forKey: Key.needsSetup)
        if let data = defaults.data(forKey: Key.toggleHotkey) {
            toggleHotkey = data.isEmpty ? nil : try? JSONDecoder().decode(HotkeyConfig.self, from: data)
        } else {
            toggleHotkey = Self.defaultHotkey
        }
    }
}

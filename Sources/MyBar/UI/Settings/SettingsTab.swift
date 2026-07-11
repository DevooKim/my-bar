import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general, info
    var id: String { rawValue }

    var label: String {
        switch self {
        case .general: return "일반"
        case .info: return "정보"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .info: return "info.circle"
        }
    }

    var tint: Color {
        switch self {
        case .general: return .gray
        case .info: return .green
        }
    }

    /// 정보 탭은 window-manager처럼 behind-window vibrancy로 그린다.
    var hasTranslucentDetail: Bool {
        switch self {
        case .info: return true
        case .general: return false
        }
    }
}

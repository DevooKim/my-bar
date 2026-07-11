import SwiftUI

/// 업데이트 창(NSWindow)의 루트 뷰. 현재 프롬프트를 렌더하고,
/// 사용자가 처리하면 dismiss 클로저로 창을 닫는다.
struct UpdateWindowRoot: View {
    @EnvironmentObject var state: UpdatePromptState
    /// AppState가 주입 — 프롬프트가 사라지면 호스트 NSWindow를 닫는다.
    var dismiss: () -> Void

    var body: some View {
        Group {
            if let prompt = state.prompt {
                UpdatePromptView(kind: prompt.kind, notes: prompt.notes) { action in
                    state.resolve(action)
                }
            } else {
                Color.clear
                    .frame(width: 1, height: 1)
            }
        }
        .onChange(of: state.prompt == nil) { _, isEmpty in
            if isEmpty { dismiss() }
        }
    }
}

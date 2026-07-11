import SwiftUI

/// 첫 실행 안내 — ⌘드래그로 아이콘을 옮기는 법을 설명한다.
struct OnboardingView: View {
    @EnvironmentObject var prefs: PreferencesStore
    var onDone: () -> Void

    private var hotkeyText: String {
        prefs.toggleHotkey?.displayString ?? "설정한 단축키"
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "menubar.arrow.up.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.tint)
            Text("메뉴바 아이콘 정리하기")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 14) {
                Label("⌘(Command)를 누른 채 메뉴바 아이콘을 드래그해 위치를 옮길 수 있습니다.", systemImage: "command")
                Label("구분자( | ) 왼쪽으로 옮긴 아이콘은 접을 때 숨겨집니다.", systemImage: "chevron.backward.2")
                Label("메인 아이콘을 클릭하거나 \(hotkeyText) 를 눌러 펼치고 숨깁니다.", systemImage: "cursorarrow.click")
            }
            .fixedSize(horizontal: false, vertical: true)

            Button("시작하기") {
                prefs.needsSetup = false
                onDone()
            }
            .keyboardShortcut(.defaultAction)
        }
        .padding(28)
        .frame(width: 440)
    }
}

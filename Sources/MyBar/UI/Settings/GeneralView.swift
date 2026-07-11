import SwiftUI
import AppKit

/// "일반" 탭 — 실행·토글·영역·아이콘 설정. window-manager와 동일한 grouped Form.
struct GeneralView: View {
    @EnvironmentObject var prefs: PreferencesStore
    @EnvironmentObject var app: AppState
    @State private var launchAtLogin = LoginItemManager.isEnabled

    /// "자동으로 다시 숨기기" 토글 — off는 rehideSeconds 0으로 표현한다.
    private var rehideEnabled: Binding<Bool> {
        Binding(
            get: { prefs.rehideSeconds > 0 },
            set: { prefs.rehideSeconds = $0 ? 10 : 0 }
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle("맥 시작 시 자동 실행", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        guard newValue != LoginItemManager.isEnabled else { return }
                        do {
                            try LoginItemManager.setEnabled(newValue)
                        } catch {
                            launchAtLogin = LoginItemManager.isEnabled
                            presentError(error, title: newValue ? "자동 실행 등록 실패" : "자동 실행 해제 실패")
                        }
                    }
            } footer: {
                Text("자동 실행은 시스템 설정 > 일반 > 로그인 항목에서도 켜고 끌 수 있습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("펼치기·숨기기") {
                HStack {
                    Text("토글 단축키")
                    Spacer()
                    HotkeyCaptureView(hotkey: $prefs.toggleHotkey)
                }
                Toggle("자동으로 다시 숨기기", isOn: rehideEnabled)
                if prefs.rehideSeconds > 0 {
                    Stepper(
                        "\(Int(prefs.rehideSeconds))초 후 숨김",
                        value: $prefs.rehideSeconds,
                        in: 1...60,
                        step: 1
                    )
                }
                Toggle("다른 곳을 클릭하면 바로 숨기기", isOn: $prefs.rehideOnOutsideClick)
            }

            Section {
                Toggle("항상 숨김 영역 사용", isOn: $prefs.alwaysHiddenEnabled)
            } footer: {
                Text("항상 숨김 영역(⋮ 구분자 왼쪽)의 아이콘은 펼쳐도 보이지 않습니다. 메인 아이콘을 ⌥(Option)+클릭하면 잠시 볼 수 있습니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("메뉴바 아이콘") {
                Picker("모양", selection: $prefs.iconStyle) {
                    ForEach(MenuIconStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
            }

            if NotchDetector.hasNotch {
                Section {
                    Label {
                        Text("이 Mac은 노치가 있어 메뉴바 공간이 부족하면 펼쳐도 일부 아이콘이 노치 뒤로 가려질 수 있습니다. 잘 쓰지 않는 아이콘은 항상 숨김 영역으로 옮기는 것을 권장합니다.")
                            .font(.caption)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Button("사용법 다시 보기") { app.openOnboarding() }
            }
        }
        .onAppear { launchAtLogin = LoginItemManager.isEnabled }
        .formStyle(.grouped)
    }

    private func presentError(_ error: Error, title: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}

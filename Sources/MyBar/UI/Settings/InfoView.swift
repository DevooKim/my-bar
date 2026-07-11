import SwiftUI
import AppKit

/// "정보" 탭 — 앱 아이콘, 버전, 업데이트 확인, 링크.
/// window-manager의 InfoView와 동일한 레이아웃.
struct InfoView: View {
    private static let repoURL = URL(string: "https://github.com/DevooKim/my-bar")!

    private static func bundleString(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "dev"
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 160, height: 160)
            Text("My Bar")
                .font(.title2.bold())
            Text("버전 \(Self.bundleString("CFBundleShortVersionString")) (\(Self.bundleString("CFBundleVersion")))")
                .foregroundColor(.secondary)
            Button("업데이트 확인") {
                Updater.checkForUpdates(silent: false)
            }
            .padding(.top, 4)
            Button("GitHub") {
                NSWorkspace.shared.open(Self.repoURL)
            }
            .buttonStyle(.link)
            Text(Self.bundleString("NSHumanReadableCopyright"))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

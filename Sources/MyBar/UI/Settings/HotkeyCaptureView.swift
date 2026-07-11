import SwiftUI
import AppKit

struct HotkeyCaptureView: View {
    @Binding var hotkey: HotkeyConfig?
    @EnvironmentObject var hotkeys: HotkeyManager
    @State private var capturing = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text(hotkey?.displayString ?? "(없음)")
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 80, alignment: .leading)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)))

            Button(capturing ? "키 누르세요..." : "변경") {
                startCapture()
            }
            .disabled(capturing)

            if hotkey != nil {
                Button("제거") { hotkey = nil }
            }
        }
        .onDisappear { stopCapture() }
    }

    private func startCapture() {
        capturing = true
        // 캡처하려는 조합이 기존 토글 단축키를 발동시키지 않게 일시정지.
        hotkeys.setPaused(true)
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // ESC
                stopCapture()
                return nil
            }
            if let cfg = HotkeyConfig.from(event: event) {
                hotkey = cfg
                stopCapture()
                return nil
            }
            return event
        }
    }

    private func stopCapture() {
        capturing = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
        hotkeys.setPaused(false)
    }
}

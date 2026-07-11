import SwiftUI

/// 설정 창 루트 — window-manager와 동일한 NavigationSplitView + vibrancy 구조.
struct SettingsRootView: View {
    @EnvironmentObject var app: AppState

    private var selection: Binding<SettingsTab> {
        Binding(get: { app.selectedTab }, set: { app.selectedTab = $0 })
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: selection) { tab in
                Label {
                    Text(tab.label)
                } icon: {
                    Image(systemName: tab.symbol)
                        .foregroundStyle(tab.tint)
                }
                .tag(tab)
            }
            .scrollContentBackground(.hidden)
            .background(
                VisualEffectView(
                    material: .hudWindow,
                    state: .followsWindowActiveState,
                    makesHostWindowTransparent: true
                )
                .ignoresSafeArea()
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("")
                .background(
                    VisualEffectView(
                        material: app.selectedTab.hasTranslucentDetail ? .hudWindow : .windowBackground,
                        state: .followsWindowActiveState,
                        disablesVibrancy: true
                    )
                    .ignoresSafeArea()
                )
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch app.selectedTab {
        case .general: GeneralView()
        case .info: InfoView()
        }
    }
}

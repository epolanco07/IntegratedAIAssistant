import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            ZStack {
                JarvisBackground()
                switch appState.selection {
                case .dashboard: DashboardView()
                case .chat: ChatView()
                case .voice: VoiceView()
                case .settings: SettingsView()
                }
            }
        }
    }
}

#Preview {
    MainWindowView().frame(width: 1100, height: 700)
}

import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 190, max: 210)
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
    MainWindowView().frame(width: 1280, height: 760)
}

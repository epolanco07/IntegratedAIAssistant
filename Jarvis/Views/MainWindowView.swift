import SwiftUI

struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var columnVisibility: NavigationSplitViewVisibility = .detailOnly

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 190, max: 210)
        } detail: {
            ZStack {
                JarvisBackground()
                switch appState.selection {
                case .dashboard: DashboardView()
                case .chat: ChatView()
                case .settings: SettingsView()
                }
            }
        }
    }
}

#Preview {
    MainWindowView().frame(width: 1440, height: 960)
}

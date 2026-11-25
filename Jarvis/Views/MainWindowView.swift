import SwiftUI

struct MainWindowView: View {
    @State private var selection: SidebarItem = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            ZStack {
                JarvisBackground()
                switch selection {
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

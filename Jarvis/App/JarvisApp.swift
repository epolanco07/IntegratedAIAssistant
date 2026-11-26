import SwiftUI

// Only @main in the project. Remove @main from (or delete) the old MyApp.swift.
@main
@MainActor
struct JarvisApp: App {
    @State private var appState = AppState(chatService: MockChatService())
    @StateObject private var voiceManager = VoiceManager()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(appState)
                .environmentObject(voiceManager)
                .preferredColorScheme(.dark)
                .frame(minWidth: 960, minHeight: 620)
                .task { await voiceManager.startContinuousListening() }
        }
        .windowToolbarStyle(.unified)
    }
}

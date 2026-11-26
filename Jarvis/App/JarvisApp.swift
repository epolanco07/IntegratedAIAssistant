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
                .frame(minWidth: 1_320, minHeight: 900)
                .task { await voiceManager.startContinuousListening() }
        }
        .defaultSize(width: 1_440, height: 960)
        .windowToolbarStyle(.unified)
    }
}

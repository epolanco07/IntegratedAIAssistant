import SwiftUI

// Only @main in the project. Remove @main from (or delete) the old MyApp.swift.
@main
@MainActor
struct JarvisApp: App {
    @State private var appState = AppState(
        chatService: HTTPChatService(baseURL: URL(string: "http://127.0.0.1:8000")!)
    )
    @StateObject private var voiceManager = VoiceManager()
    @StateObject private var backendLauncher = LocalBackendLauncher()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environment(appState)
                .environmentObject(voiceManager)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1_320, minHeight: 900)
                .task {
                    appState.connectionStatus = .checking
                    appState.connectionStatus = await backendLauncher.startIfNeeded()
                    await voiceManager.startContinuousListening()
                }
        }
        .defaultSize(width: 1_440, height: 960)
        .windowToolbarStyle(.unified)
    }
}

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
                    // Voice can start right away; it should not wait for a
                    // network health check or a slow agent response.
                    configureVoiceConversation()
                    await voiceManager.startContinuousListening()
                    appState.connectionStatus = .checking
                    appState.connectionStatus = await backendLauncher.startIfNeeded()
                }
        }
        .defaultSize(width: 1_440, height: 960)
        .windowToolbarStyle(.unified)
    }

    private func configureVoiceConversation() {
        voiceManager.onFinalTranscript = { transcript in
            Task { @MainActor in
                // The local backend may have stopped after app launch. Verify
                // it for each spoken turn so wake-word requests never vanish.
                appState.connectionStatus = await backendLauncher.startIfNeeded()
                let reply = await appState.send(transcript)
                voiceManager.setProcessing(false)
                if let reply {
                    voiceManager.setAwaitingFollowUp(reply.text.contains("?"))
                    await voiceManager.speak(reply.text)
                } else {
                    await voiceManager.startContinuousListening()
                }
            }
        }
    }
}

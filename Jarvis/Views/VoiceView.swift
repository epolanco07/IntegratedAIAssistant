import SwiftUI

struct VoiceView: View {
    @StateObject private var voiceManager = VoiceManager()

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    commandHeader
                    Spacer(minLength: 22)
                    Button { Task { await toggleRecording() } } label: { CommandOrb(mode: orbMode) }
                        .buttonStyle(.plain)
                        .help(voiceManager.recorder.state == .recording ? "Stop recording" : "Start push-to-talk")
                    VStack(spacing: 8) {
                        Text(statusTitle).font(.system(size: 25, weight: .semibold, design: .rounded))
                        Text(statusDetail).font(.callout).foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 2)
                    controlRow.padding(.top, 22)
                    transcriptPanel.padding(.top, 34).frame(maxWidth: min(680, proxy.size.width - 48))
                    Spacer(minLength: 34)
                }
                .frame(minHeight: proxy.size.height).frame(maxWidth: .infinity).padding(.horizontal, 24)
            }
        }
    }

    private var commandHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Voice console").font(.title2.weight(.semibold))
                Text("Local audio is ready. Conversation requires the backend.").font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 7) {
                Circle().fill(Theme.warning).frame(width: 7, height: 7)
                Text("BACKEND OFFLINE").font(.caption2.weight(.semibold)).tracking(0.8)
            }
            .foregroundStyle(Theme.warning).padding(.horizontal, 10).padding(.vertical, 6)
            .background(Theme.warning.opacity(0.1), in: Capsule())
        }
        .padding(.top, 28)
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button { Task { await toggleRecording() } } label: {
                Label(voiceManager.recorder.state == .recording ? "Stop listening" : "Speak to JARVIS", systemImage: voiceManager.recorder.state == .recording ? "stop.fill" : "mic.fill")
                    .frame(minWidth: 154)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accentDeep).controlSize(.large)
            Button { voiceManager.interrupt() } label: { Label("Interrupt", systemImage: "hand.raised.fill") }
                .buttonStyle(.bordered).controlSize(.large).disabled(!voiceManager.player.isSpeaking)
        }
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Conversation signal").font(.headline)
                Spacer()
                Text(microphoneLabel).font(.caption.weight(.medium)).foregroundStyle(microphoneColor)
            }
            Divider().overlay(Theme.border)
            Text(voiceManager.transcript.isEmpty ? "Press Speak to JARVIS, then describe what you need. The local microphone capture will be ready for backend transcription when it is connected." : voiceManager.transcript)
                .font(.callout).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()
    }

    private var orbMode: CommandOrb.Mode {
        if voiceManager.player.isSpeaking { return .speaking }
        return voiceManager.recorder.state == .recording ? .listening : .idle
    }
    private var statusTitle: String {
        switch voiceManager.recorder.state { case .idle: "How can I help?"; case .recording: "I’m listening"; case .denied: "Microphone access is needed"; case .failed: "Audio is unavailable" }
    }
    private var statusDetail: String {
        switch voiceManager.recorder.state { case .idle: "Click the orb or use the voice control to begin."; case .recording: "Listening locally — stop when you’re finished."; case .denied: "Enable microphone permission in System Settings, then try again."; case .failed(let detail): detail }
    }
    private var microphoneLabel: String {
        switch voiceManager.recorder.state { case .idle: "READY"; case .recording: "LISTENING"; case .denied: "PERMISSION NEEDED"; case .failed: "AUDIO ERROR" }
    }
    private var microphoneColor: Color {
        switch voiceManager.recorder.state { case .recording: Theme.success; case .denied, .failed: Theme.danger; case .idle: Theme.accent }
    }
    private func toggleRecording() async {
        if voiceManager.recorder.state == .recording { voiceManager.endPushToTalk() }
        else { await voiceManager.beginPushToTalk() }
    }
}

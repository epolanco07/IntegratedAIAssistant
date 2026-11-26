import SwiftUI

struct VoiceView: View {
    @StateObject private var voiceManager = VoiceManager()

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    commandHeader
                    HStack(alignment: .center, spacing: 30) {
                        leftDeck.frame(width: 190)
                        voiceCore
                        rightDeck.frame(width: 190)
                    }
                    .padding(.top, 18)
                    transcriptPanel
                        .padding(.top, 26)
                        .frame(maxWidth: min(740, proxy.size.width - 48))
                    Spacer(minLength: 28)
                }
                .frame(minHeight: proxy.size.height)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
            }
        }
    }

    private var commandHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Voice console").font(.title2.weight(.semibold))
                Text("LOCAL AUDIO INTERFACE · BACKEND SESSION NOT CONNECTED")
                    .font(.caption2.weight(.medium)).tracking(0.8).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            HStack(spacing: 7) {
                Circle().fill(Theme.warning).frame(width: 7, height: 7)
                Text("BACKEND OFFLINE").font(.caption2.weight(.semibold)).tracking(0.8)
            }
            .foregroundStyle(Theme.warning).padding(.horizontal, 10).padding(.vertical, 6)
            .background(Theme.warning.opacity(0.12), in: Capsule())
        }
        .padding(.top, 28)
    }

    private var voiceCore: some View {
        VStack(spacing: 0) {
            Button { Task { await toggleRecording() } } label: { CommandOrb(mode: orbMode) }
                .buttonStyle(.plain)
                .help(voiceManager.recorder.state == .recording ? "Stop recording" : "Start push-to-talk")
            VStack(spacing: 7) {
                Text(statusTitle).font(.system(size: 25, weight: .semibold, design: .rounded))
                Text(statusDetail).font(.callout).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: 390)
            controlRow.padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var leftDeck: some View {
        VStack(spacing: 12) {
            TelemetryPanel(title: "Input", symbol: "mic.fill") {
                telemetryRow("DEVICE", "System default")
                telemetryRow("STATUS", microphoneLabel, valueColor: microphoneColor)
                signalBars(active: voiceManager.recorder.state == .recording)
            }
            TelemetryPanel(title: "Prompt", symbol: "waveform.path") {
                Text("Push to talk to create a local audio stream.")
                    .font(.caption).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var rightDeck: some View {
        VStack(spacing: 12) {
            TelemetryPanel(title: "Session", symbol: "antenna.radiowaves.left.and.right") {
                telemetryRow("SERVICE", "Unavailable", valueColor: Theme.warning)
                telemetryRow("MODE", "Preview")
                telemetryRow("ROUTE", "Local only")
            }
            TelemetryPanel(title: "Playback", symbol: "speaker.wave.2.fill") {
                telemetryRow("STATE", voiceManager.player.isSpeaking ? "Speaking" : "Idle", valueColor: voiceManager.player.isSpeaking ? Theme.accent : Theme.textSecondary)
                Button { voiceManager.interrupt() } label: { Label("Interrupt", systemImage: "hand.raised.fill") }
                    .buttonStyle(.bordered).controlSize(.small).disabled(!voiceManager.player.isSpeaking)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button { Task { await toggleRecording() } } label: {
                Label(voiceManager.recorder.state == .recording ? "Stop listening" : "Speak to JARVIS", systemImage: voiceManager.recorder.state == .recording ? "stop.fill" : "mic.fill")
                    .frame(minWidth: 154)
            }
            .buttonStyle(.borderedProminent).tint(Theme.accentDeep).controlSize(.large)
        }
    }

    private var transcriptPanel: some View {
        TelemetryPanel(title: "Conversation signal", symbol: "text.bubble.fill") {
            Text(voiceManager.transcript.isEmpty ? "Voice capture is ready. Backend transcription and conversation will appear here when a voice session is connected." : voiceManager.transcript)
                .font(.callout).foregroundStyle(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func telemetryRow(_ label: String, _ value: String, valueColor: Color = Theme.textPrimary) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption2.weight(.medium)).tracking(0.6).foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 8)
            Text(value).font(.caption.weight(.medium)).foregroundStyle(valueColor).multilineTextAlignment(.trailing)
        }
    }

    private func signalBars(active: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<12, id: \.self) { index in
                Capsule()
                    .fill(Theme.accent.opacity(active ? (index.isMultiple(of: 3) ? 1 : 0.55) : 0.24))
                    .frame(width: 5, height: CGFloat(7 + (index * 11) % 24))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private var orbMode: CommandOrb.Mode {
        if voiceManager.player.isSpeaking { return .speaking }
        return voiceManager.recorder.state == .recording ? .listening : .idle
    }
    private var statusTitle: String {
        switch voiceManager.recorder.state { case .idle: "How can I help?"; case .recording: "I’m listening"; case .denied: "Microphone access is needed"; case .failed: "Audio is unavailable" }
    }
    private var statusDetail: String {
        switch voiceManager.recorder.state { case .idle: "Click the core or start a voice session."; case .recording: "Listening locally — stop when you’re finished."; case .denied: "Enable microphone permission in System Settings, then try again."; case .failed(let detail): detail }
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

private struct TelemetryPanel<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: symbol).font(.caption.weight(.semibold)).foregroundStyle(Theme.accent)
                Text(title.uppercased()).font(.caption2.weight(.semibold)).tracking(0.9).foregroundStyle(Theme.textSecondary)
            }
            Divider().overlay(Theme.border)
            content
        }
        .padding(13)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border))
    }
}

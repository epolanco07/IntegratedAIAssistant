import SwiftUI

struct VoiceView: View {
    @Environment(AppState.self) private var appState
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
        VStack(spacing: 12) {
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
            HStack(spacing: 6) {
                HUDShortcut(title: "VOICE", isActive: true) { appState.selection = .voice }
                HUDShortcut(title: "CHAT") { appState.selection = .chat }
                HUDShortcut(title: "CENTER") { appState.selection = .dashboard }
                HUDShortcut(title: "SETTINGS") { appState.selection = .settings }
                Spacer()
            }
        }
        .padding(.top, 28)
    }

    private var voiceCore: some View {
        VStack(spacing: 0) {
            ZStack {
                Button { Task { await toggleRecording() } } label: { CommandOrb(mode: orbMode) }
                    .buttonStyle(.plain)
                    .help(voiceManager.recorder.state == .recording ? "Stop recording" : "Start push-to-talk")
                radialShortcut("CHAT", at: CGSize(width: -145, height: -92)) { appState.selection = .chat }
                radialShortcut("CENTER", at: CGSize(width: 145, height: -92)) { appState.selection = .dashboard }
                radialShortcut("SETTINGS", at: CGSize(width: 152, height: 98)) { appState.selection = .settings }
                radialShortcut("VOICE", at: CGSize(width: -152, height: 98)) { appState.selection = .voice }
            }
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

    private func radialShortcut(_ title: String, at offset: CGSize, action: @escaping () -> Void) -> some View {
        Button { action() } label: {
            Text(title).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(0.8)
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 7).padding(.vertical, 5)
                .background { ChamferedRectangle(cut: 4).fill(Theme.background.opacity(0.72)) }
                .overlay { ChamferedRectangle(cut: 4).stroke(Theme.border, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .offset(x: offset.width, y: offset.height)
    }

    private func signalBars(active: Bool) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<12, id: \.self) { index in
                    let amplitude = abs(sin(phase * (active ? 4.0 : 1.2) + Double(index) * 0.72))
                    Capsule()
                        .fill(Theme.accent.opacity(active ? 0.9 : 0.38))
                        .frame(width: 5, height: 7 + CGFloat(amplitude) * (active ? 27 : 9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
        }
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
        .background {
            ChamferedRectangle(cut: 8)
                .fill(LinearGradient(colors: [Theme.surface.opacity(0.45), Theme.accentDeep.opacity(0.34)], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay { ChamferedRectangle(cut: 8).stroke(Theme.border, lineWidth: 1) }
    }
}

private struct HUDShortcut: View {
    let title: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button { action() } label: {
            Text(title).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(0.8)
                .foregroundStyle(isActive ? Theme.warning : Theme.accent)
                .padding(.horizontal, 11).padding(.vertical, 6)
                .background { ChamferedRectangle(cut: 5).fill(Theme.background.opacity(0.78)) }
                .overlay { ChamferedRectangle(cut: 5).stroke(isActive ? Theme.warning.opacity(0.8) : Theme.border, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

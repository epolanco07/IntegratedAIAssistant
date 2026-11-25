import SwiftUI

struct VoiceView: View {
    @StateObject private var voiceManager = VoiceManager()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle")
                    Text("Voice is not operational yet. This screen is a visual preview only.").font(.callout)
                }
                .foregroundStyle(Theme.warning)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.warning.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                orb.frame(height: 220)

                VStack(spacing: 8) {
                    Text(statusTitle).font(.title3.weight(.semibold))
                    HStack(spacing: 8) {
                        StatusBadge(text: microphoneLabel, kind: microphoneKind)
                        StatusBadge(text: voiceManager.player.isSpeaking ? "Playback speaking" : "Playback idle", kind: .neutral)
                    }
                }

                HStack(spacing: 16) {
                    Button { Task { await toggleRecording() } } label: {
                        Label(voiceManager.recorder.state == .recording ? "Stop recording" : "Push to talk", systemImage: "mic.fill")
                            .font(.headline)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(Theme.accentGradient, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    Button { voiceManager.interrupt() } label: { Label("Interrupt", systemImage: "hand.raised.fill") }
                        .buttonStyle(.bordered)
                        .disabled(!voiceManager.player.isSpeaking)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SectionTitle("Live transcript")
                    Text(voiceManager.transcript.isEmpty ? "Audio capture is local only until a backend voice service is connected." : voiceManager.transcript)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("Conversation transcript")
                    MessageView(message: ChatMessage.samples[0])
                    MessageView(message: ChatMessage.samples[1])
                }
                .cardStyle()

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Voice settings").font(.headline)
                        Text("Target voice: British English, masculine, calm, moderate pace.")
                            .font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    StatusBadge(text: "Placeholder", kind: .neutral)
                }
                .cardStyle()
            }
            .padding(28)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
    }

    private var statusTitle: String {
        switch voiceManager.recorder.state {
        case .idle: "Ready"
        case .recording: "Listening"
        case .denied: "Microphone access needed"
        case .failed: "Audio unavailable"
        }
    }

    private var microphoneLabel: String {
        switch voiceManager.recorder.state {
        case .idle: "Microphone ready"
        case .recording: "Listening"
        case .denied: "Microphone denied"
        case .failed: "Microphone error"
        }
    }

    private var microphoneKind: StatusBadge.Kind {
        switch voiceManager.recorder.state {
        case .recording: .connected
        case .denied, .failed: .error
        case .idle: .neutral
        }
    }

    private func toggleRecording() async {
        if voiceManager.recorder.state == .recording { voiceManager.endPushToTalk() }
        else { await voiceManager.beginPushToTalk() }
    }

    private var orb: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .strokeBorder(Theme.accent.opacity(0.25 - Double(ring) * 0.06), lineWidth: 1.5)
                    .frame(width: 130 + CGFloat(ring) * 36, height: 130 + CGFloat(ring) * 36)
            }
            Circle()
                .fill(RadialGradient(colors: [Theme.accentDeep.opacity(0.9), Theme.accentDeep.opacity(0.25)],
                                     center: .center, startRadius: 4, endRadius: 70))
                .frame(width: 120, height: 120)
                .shadow(color: Theme.accentDeep.opacity(0.5), radius: 12)
        }
    }
}

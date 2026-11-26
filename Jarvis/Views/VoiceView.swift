import SwiftUI

struct VoiceView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var voiceManager: VoiceManager

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    commandHeader
                    HStack(alignment: .center, spacing: 18) {
                        leftDeck.frame(width: 162).padding(.top, 54)
                        voiceCore
                        rightDeck.frame(width: 218).padding(.bottom, 32)
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
                    Text("JARVIS // VOICE").font(.system(size: 18, weight: .bold, design: .monospaced))
                    Text("CAPTURE BUS // LOCAL")
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
            ZStack {
                Button { Task { await toggleListener() } } label: { CommandOrb(mode: orbMode) }
                    .buttonStyle(.plain)
                    .help(voiceManager.recorder.state == .recording ? "Pause listener" : "Resume listener")
                radialShortcut("CHAT", at: CGSize(width: -145, height: -92)) { appState.selection = .chat }
                radialShortcut("CENTER", at: CGSize(width: 145, height: -92)) { appState.selection = .dashboard }
                radialShortcut("SETTINGS", at: CGSize(width: 152, height: 98)) { appState.selection = .settings }
                radialShortcut("VOICE", at: CGSize(width: -152, height: 98)) { appState.selection = .voice }
            }
            VStack(spacing: 7) {
                Text(statusTitle).font(.system(size: 18, weight: .bold, design: .monospaced)).tracking(1.2)
                Text(statusDetail).font(.caption.weight(.medium)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: 390)
            controlRow.padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
    }

    private var leftDeck: some View {
        VStack(spacing: 12) {
            TelemetryPanel(title: "IN", symbol: "mic.fill") {
                telemetryRow("DEV", "DEFAULT")
                telemetryRow("STATUS", microphoneLabel, valueColor: microphoneColor)
                signalBars(active: voiceManager.recorder.state == .recording)
            }
            InstrumentLog()
                .frame(height: 92)
            TelemetryPanel(title: "SIG", symbol: "waveform.path") {
                telemetryRow("STORE", "NONE")
                telemetryRow("ROUTE", "LOCAL")
            }
        }
    }

    private var rightDeck: some View {
        VStack(spacing: 12) {
            ClockPanel()
                .frame(height: 132)
            TelemetryPanel(title: "SESS", symbol: "antenna.radiowaves.left.and.right") {
                telemetryRow("ID", "NONE")
                telemetryRow("MODE", "PREVIEW")
                telemetryRow("ROUTE", "LOCAL")
            }
            TelemetryPanel(title: "PLAY", symbol: "speaker.wave.2.fill") {
                telemetryRow("STATE", voiceManager.player.isSpeaking ? "Speaking" : "Idle", valueColor: voiceManager.player.isSpeaking ? Theme.accent : Theme.textSecondary)
                Button { voiceManager.interrupt() } label: { Label("Interrupt", systemImage: "hand.raised.fill") }
                    .buttonStyle(.bordered).controlSize(.small).disabled(!voiceManager.player.isSpeaking)
            }
        }
    }

    private var controlRow: some View {
        HStack(spacing: 12) {
            Button { Task { await toggleListener() } } label: {
                Label(voiceManager.recorder.state == .recording ? "Pause listener" : "Resume listener", systemImage: voiceManager.recorder.state == .recording ? "pause.fill" : "play.fill")
                    .frame(minWidth: 154)
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background { ChamferedRectangle(cut: 6).fill(Theme.accentDeep.opacity(0.45)) }
            .overlay { ChamferedRectangle(cut: 6).stroke(Theme.accent, lineWidth: 1) }
        }
    }

    private var transcriptPanel: some View {
        TelemetryPanel(title: "CAPTURE", symbol: "text.bubble.fill") {
            Text(voiceManager.transcript.isEmpty ? "> VOICE CAPTURE READY // AWAITING BACKEND" : voiceManager.transcript)
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
        switch voiceManager.recorder.state { case .idle: "PAUSED"; case .recording: "LISTENING"; case .denied: "MIC PERMISSION"; case .failed: "AUDIO FAULT" }
    }
    private var statusDetail: String {
        switch voiceManager.recorder.state { case .idle: "LOCAL LISTENER"; case .recording: "LOCAL // ACTIVE"; case .denied: "CHECK SYSTEM SETTINGS"; case .failed: "CHECK AUDIO BUS" }
    }
    private var microphoneLabel: String {
        switch voiceManager.recorder.state { case .idle: "READY"; case .recording: "LISTENING"; case .denied: "PERMISSION NEEDED"; case .failed: "AUDIO ERROR" }
    }
    private var microphoneColor: Color {
        switch voiceManager.recorder.state { case .recording: Theme.success; case .denied, .failed: Theme.danger; case .idle: Theme.accent }
    }
    private func toggleListener() async {
        if voiceManager.recorder.state == .recording { voiceManager.pauseListening() }
        else { await voiceManager.startContinuousListening() }
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

private struct InstrumentLog: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 5) {
                Text("LOG // (context.date.formatted(date: .omitted, time: .standard))")
                Text("MIC OPEN")
                Text("VAD ARMED")
                Text("SESS: NONE")
            }
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundStyle(Theme.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(9)
            .background { ChamferedRectangle(cut: 4).fill(Theme.background.opacity(0.54)) }
            .overlay { ChamferedRectangle(cut: 4).stroke(Theme.border.opacity(0.55), lineWidth: 1) }
        }
    }
}

private struct ClockPanel: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let calendar = Calendar.current
            let day = calendar.component(.day, from: context.date)
            VStack(alignment: .leading, spacing: 0) {
                Text(context.date.formatted(.dateTime.month(.abbreviated).weekday(.abbreviated).year()))
                    .font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(0.7).foregroundStyle(Theme.textSecondary)
                HStack(alignment: .lastTextBaseline, spacing: 9) {
                    Text(String(format: "%02d", day)).font(.system(size: 46, weight: .thin, design: .monospaced)).foregroundStyle(Theme.signalCore)
                    Text(context.date.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundStyle(Theme.accent)
                }
                Spacer()
                Rectangle().fill(Theme.warning).frame(width: 28, height: 2)
            }
            .padding(11)
            .background { ChamferedRectangle(cut: 10).fill(Theme.accentDeep.opacity(0.34)) }
            .overlay { ChamferedRectangle(cut: 10).stroke(Theme.warning.opacity(0.8), lineWidth: 1) }
        }
    }
}

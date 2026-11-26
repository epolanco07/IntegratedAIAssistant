import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @EnvironmentObject private var voiceManager: VoiceManager
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                HStack(alignment: .top, spacing: 12) {
                    coreOverview.frame(width: 180)
                    assistantCore.frame(maxWidth: .infinity, minHeight: 420)
                    activityFeed.frame(width: 230)
                }
                HStack(alignment: .top, spacing: 12) {
                    agentsPanel.frame(maxWidth: .infinity)
                    recentActivity.frame(width: 260)
                    quickActions.frame(width: 210)
                }
                HStack(alignment: .top, spacing: 12) {
                    systemStatus.frame(width: 300)
                    recentConversations.frame(maxWidth: .infinity)
                }
            }
            .frame(minWidth: 1_040, alignment: .leading)
            .padding(22)
        }
    }

    private var header: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("ARTHUR // COMMAND CENTER").font(.system(size: 16, weight: .bold, design: .monospaced))
                    Spacer()
                    Text(context.date.formatted(date: .abbreviated, time: .standard)).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(Theme.accent)
                }
            }
        }
    }

    private var coreOverview: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Core overview")
            ForEach([("VOICE", "LOCAL"), ("MEMORY", "NONE"), ("AGENTS", "PREVIEW"), ("BACKEND", "OFFLINE")], id: \.0) { item in
                HStack { Text(item.0).font(.caption2.monospaced()); Spacer(); Text(item.1).font(.caption2.monospaced()).foregroundStyle(item.1 == "OFFLINE" ? Theme.warning : Theme.accent) }
                    .padding(8).background(Theme.background.opacity(0.55), in: ChamferedRectangle(cut: 4))
            }
        }.cardStyle()
    }

    private var assistantCore: some View {
        VStack(spacing: 5) {
            ZStack {
                CommandOrb(mode: orbMode).scaleEffect(1.04)
            }
            .frame(height: 370)
            Text(listenerDetail)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .foregroundStyle(Theme.textSecondary)
            Button { Task { await toggleListener() } } label: {
                Label(listenerActionTitle, systemImage: voiceManager.recorderState == .recording ? "pause.fill" : "play.fill")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.7)
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.plain)
            .background { ChamferedRectangle(cut: 5).fill(Theme.accentDeep.opacity(0.28)) }
            .overlay { ChamferedRectangle(cut: 5).stroke(Theme.border.opacity(0.75), lineWidth: 1) }
            .padding(.bottom, 8)
        }
    }

    private var orbMode: CommandOrb.Mode {
        if voiceManager.player.isSpeaking { return .speaking }
        return voiceManager.recorderState == .recording ? .listening : .idle
    }

    private var listenerDetail: String {
        switch voiceManager.recorderState {
        case .recording: "CONTINUOUS LISTENING // LOCAL"
        case .idle: "LISTENER PAUSED // LOCAL"
        case .denied: "MICROPHONE ACCESS REQUIRED"
        case .failed: "AUDIO INPUT UNAVAILABLE"
        }
    }

    private var listenerActionTitle: String {
        voiceManager.recorderState == .recording ? "PAUSE LISTENER" : "RESUME LISTENER"
    }

    private func toggleListener() async {
        if voiceManager.recorderState == .recording {
            voiceManager.pauseListening()
        } else {
            await voiceManager.startContinuousListening()
        }
    }

    private var activityFeed: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("Intelligence feed")
            ForEach(ActivityItem.samples) { item in
                HStack(alignment: .top, spacing: 7) { Circle().fill(Theme.accent).frame(width: 5, height: 5).padding(.top, 4); Text(item.title).font(.caption).lineLimit(1) }
                Divider().overlay(Theme.border.opacity(0.45))
            }
        }.cardStyle()
    }

    private var agentsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Active modules")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                ForEach(["VOICE BUS", "CHAT BUS", "MEMORY", "TOOLS", "ROUTING", "SYSTEM"], id: \.self) { name in
                    HStack { Image(systemName: "circle.hexagongrid").foregroundStyle(Theme.accent); Text(name).font(.caption2.monospaced()); Spacer() }
                        .padding(8).background(Theme.accentDeep.opacity(0.18), in: ChamferedRectangle(cut: 4))
                }
            }
        }.cardStyle()
    }

    private var systemStatus: some View {
        VStack(spacing: 8) {
            statusItem("Assistant", "Standing by", "sparkle", Theme.accent, badge: ("Local preview", .mock))
            Divider().overlay(Theme.border.opacity(0.55))
            statusItem("Backend", "Not connected", "server.rack", Theme.warning, badge: ("Offline", .neutral))
        }
        .padding(12)
        .background { ChamferedRectangle(cut: 10).fill(Theme.surface.opacity(0.36)) }
        .overlay { ChamferedRectangle(cut: 10).stroke(Theme.border, lineWidth: 1) }
        .shadow(color: Theme.accent.opacity(0.12), radius: 10, y: 3)
    }

    private func statusItem(_ title: String, _ value: String, _ symbol: String, _ tint: Color,
                            badge: (String, StatusBadge.Kind)) -> some View {
        HStack(spacing: 9) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased()).font(.caption2.weight(.medium)).tracking(0.7).foregroundStyle(Theme.textSecondary).lineLimit(1)
                Text(value).font(.caption.weight(.semibold)).lineLimit(1)
            }
            Spacer(minLength: 4)
            StatusBadge(text: badge.0, kind: badge.1)
        }
        .frame(maxWidth: .infinity)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Quick actions")
            VStack(spacing: 6) {
                ForEach([("New conversation", "plus.bubble"), ("Start voice", "mic"), ("Settings", "gearshape")], id: \.0) { item in
                    Button { performQuickAction(item.0) } label: {
                        Label(item.0, systemImage: item.1).font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 8).padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .background { ChamferedRectangle(cut: 4).fill(Theme.background.opacity(0.5)) }
                    .overlay { ChamferedRectangle(cut: 4).stroke(Theme.border.opacity(0.55), lineWidth: 1) }
                }
            }
        }.cardStyle()
    }

    private func performQuickAction(_ title: String) {
        switch title {
        case "New conversation": appState.createConversation()
        case "Start voice": appState.selection = .dashboard
        case "Settings": appState.selection = .settings
        default: break
        }
    }

    private var recentConversations: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Recent conversations", trailing: "Sample")
            ForEach(ConversationSummary.samples) { convo in
                VStack(alignment: .leading, spacing: 2) {
                    Text(convo.title).lineLimit(1)
                    Text(convo.preview).font(.caption).foregroundStyle(Theme.textSecondary).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Recent activity", trailing: "Sample")
            ForEach(ActivityItem.samples) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.systemImage).foregroundStyle(Theme.accent).frame(width: 20)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                        Text(item.detail).font(.caption).foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Text(item.when).font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct IntegrationCard: View {
    let item: IntegrationItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: item.systemImage).foregroundStyle(Theme.accent)
                Text(item.name).font(.headline)
                Spacer()
                StatusBadge(text: "Placeholder", kind: .neutral)
            }
            row("Access", item.access)
            row("Auth", "Not authenticated")
            row("Last sync", "Never")
            Text(item.capabilities).font(.caption).foregroundStyle(Theme.textSecondary)
        }
        .cardStyle()
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Theme.textSecondary)
            Spacer()
            Text(value)
        }
        .font(.caption)
    }
}

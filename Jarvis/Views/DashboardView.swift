import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                HStack(alignment: .top, spacing: 12) {
                    coreOverview.frame(width: 190)
                    assistantCore.frame(maxWidth: .infinity, minHeight: 220)
                    activityFeed.frame(width: 240)
                }
                HStack(alignment: .top, spacing: 12) {
                    agentsPanel.frame(maxWidth: .infinity)
                    recentActivity.frame(width: 270)
                    quickActions.frame(width: 220)
                }
                HStack(alignment: .top, spacing: 12) {
                    systemStatus.frame(width: 300)
                    recentConversations.frame(maxWidth: .infinity)
                }
            }
            .padding(18)
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
        ZStack {
            CommandOrb(mode: .listening).scaleEffect(0.62)
            VStack(spacing: 5) {
                Text("ARTHUR").font(.system(size: 28, weight: .bold, design: .monospaced)).tracking(5).foregroundStyle(Theme.accent)
                Text("LOCAL CORE // PREVIEW").font(.caption2.monospaced()).foregroundStyle(Theme.textSecondary)
            }.offset(y: 4)
        }
        .background { ChamferedRectangle(cut: 12).fill(Theme.surface.opacity(0.52)) }
        .overlay { ChamferedRectangle(cut: 12).stroke(Theme.border, lineWidth: 1) }
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
        HStack(spacing: 0) {
            statusItem("Assistant", "Standing by", "sparkle", Theme.accent, badge: ("Local preview", .mock))
            Divider().overlay(Theme.border).padding(.vertical, 8)
            statusItem("Backend", "Not connected", "server.rack", Theme.warning, badge: ("Offline", .neutral))
        }
        .padding(.vertical, 8)
        .background(Theme.surface.opacity(0.85), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.border))
    }

    private func statusItem(_ title: String, _ value: String, _ symbol: String, _ tint: Color,
                            badge: (String, StatusBadge.Kind)) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased()).font(.caption2.weight(.medium)).tracking(0.7).foregroundStyle(Theme.textSecondary)
                Text(value).font(.headline)
            }
            Spacer(minLength: 12)
            StatusBadge(text: badge.0, kind: badge.1)
        }
        .padding(.horizontal, 16)
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
        case "Start voice": appState.selection = .voice
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

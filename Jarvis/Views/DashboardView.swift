import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                systemStatus
                quickActions
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    recentConversations
                    recentActivity
                }
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("Integrations", trailing: "Placeholders. Nothing is connected.")
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(IntegrationItem.samples) { IntegrationCard(item: $0) }
                    }
                }
            }
            .padding(28)
        }
    }

    private var header: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 4) {
                Text("Command center").font(.largeTitle.weight(.semibold))
                Text(context.date.formatted(date: .complete, time: .standard))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
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
            HStack(spacing: 10) {
                ForEach([("New conversation", "plus.bubble"), ("Start voice", "mic"), ("Settings", "gearshape")], id: \.0) { item in
                    Button { performQuickAction(item.0) } label: {
                        Label(item.0, systemImage: item.1).padding(.horizontal, 6).padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
        }
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

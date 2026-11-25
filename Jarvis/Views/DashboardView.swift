import SwiftUI

struct DashboardView: View {
    private let columns = [GridItem(.adaptive(minimum: 260), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                LazyVGrid(columns: columns, spacing: 16) {
                    statusCard("Assistant", "Standing by", "circle.dotted", Theme.textSecondary, badge: ("Preview", .mock))
                    statusCard("Backend", "Not connected", "server.rack", Theme.textSecondary, badge: ("Offline", .neutral))
                }
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
                Text("Welcome back").font(.largeTitle.weight(.semibold))
                Text(context.date.formatted(date: .complete, time: .standard))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func statusCard(_ title: String, _ value: String, _ symbol: String, _ tint: Color,
                            badge: (String, StatusBadge.Kind)) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption).foregroundStyle(Theme.textSecondary)
                Text(value).font(.headline)
            }
            Spacer()
            StatusBadge(text: badge.0, kind: badge.1)
        }
        .cardStyle()
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Quick actions")
            HStack(spacing: 10) {
                ForEach([("New conversation", "plus.bubble"), ("Start voice", "mic"), ("Settings", "gearshape")], id: \.0) { item in
                    Button {} label: {
                        Label(item.0, systemImage: item.1).padding(.horizontal, 6).padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
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

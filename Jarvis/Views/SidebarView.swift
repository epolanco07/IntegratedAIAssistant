import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                AssistantAvatar(size: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text("JARVIS").font(.headline).tracking(2)
                    Text("Personal assistant").font(.caption2).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(16)

            Button {} label: {
                Label("New conversation", systemImage: "plus").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accentDeep)
            .controlSize(.large)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            VStack(spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(title: item.title, systemImage: item.systemImage, isSelected: selection == item) {
                        selection = item
                    }
                }
            }
            .padding(.horizontal, 8)

            SectionTitle("Conversations")
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(ConversationSummary.samples) { convo in
                        SidebarRow(title: convo.title, systemImage: "text.bubble", isSelected: false) {
                            selection = .chat
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Divider().overlay(Theme.border)
                StatusBadge(text: "Backend not connected", kind: .neutral)
                Text("Interface preview").font(.caption2).foregroundStyle(Theme.warning)
            }
            .padding(12)
        }
        .background(Theme.surface)
    }
}

private struct SidebarRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? Theme.accent : Theme.textSecondary)
                Text(title).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Theme.accent.opacity(0.14) : (hovering ? Color.white.opacity(0.05) : .clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

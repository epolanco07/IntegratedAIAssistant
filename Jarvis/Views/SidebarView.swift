import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                AssistantAvatar(size: 34)
                VStack(alignment: .leading, spacing: 0) {
                    Text("ARTHUR").font(.system(size: 14, weight: .bold, design: .monospaced)).tracking(2.2)
                    Text("COMMAND CONSOLE").font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1.1).foregroundStyle(Theme.accent)
                }
            }
            .padding(16)

            VStack(spacing: 2) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarRow(title: item.title, systemImage: item.systemImage, isSelected: appState.selection == item) {
                        appState.selection = item
                    }
                }
            }
            .padding(.horizontal, 8)

            HStack {
                Text("CONVERSATIONS")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(Theme.textSecondary)
                Button { appState.createConversation() } label: { Image(systemName: "plus") }
                    .buttonStyle(.plain).foregroundStyle(Theme.textSecondary)
                    .help("New conversation")
            }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 6)

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(appState.conversations) { convo in
                        SidebarRow(title: convo.title, systemImage: "text.bubble", isSelected: appState.selectedConversationID == convo.id) {
                            appState.selectConversation(convo.id)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 6) {
                Divider().overlay(Theme.border)
                HStack(spacing: 7) {
                    Circle().fill(Theme.warning).frame(width: 7, height: 7)
                    Text("BACKEND OFFLINE").font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(0.8)
                }
                .foregroundStyle(Theme.warning)
                Text("LOCAL PREVIEW MODE").font(.system(size: 8, weight: .medium, design: .monospaced)).tracking(0.7).foregroundStyle(Theme.textSecondary)
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
                Text(title.uppercased()).font(.system(size: 10, weight: .bold, design: .monospaced)).tracking(0.8).lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(
                ChamferedRectangle(cut: 4)
                    .fill(isSelected ? Theme.accent.opacity(0.18) : (hovering ? Theme.accent.opacity(0.07) : .clear))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

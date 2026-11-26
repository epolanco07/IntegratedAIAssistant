import SwiftUI

struct ChatView: View {
    @Environment(AppState.self) private var appState
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                AssistantAvatar(size: 30)
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.selectedConversation?.title ?? "New conversation").font(.title3.weight(.semibold))
                    Text("TEXT CONVERSATION · LOCAL PREVIEW").font(.caption2.weight(.medium)).tracking(0.7).foregroundStyle(Theme.warning)
                }
                Spacer()
                Button { appState.selection = .dashboard } label: { Label("Command Center", systemImage: "mic.fill") }
                    .buttonStyle(.bordered)
                Button { appState.createConversation() } label: { Label("New", systemImage: "square.and.pencil") }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 18)

            Divider().overlay(Theme.border)

            ScrollView {
                LazyVStack(spacing: 18) {
                    if let conversation = appState.selectedConversation, !conversation.messages.isEmpty {
                        ForEach(conversation.messages) { MessageView(message: $0) }
                    } else { emptyState }
                    if appState.isSending { thinkingRow }
                }
                .padding(24)
            }

            if let error = appState.chatError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                    Spacer()
                    Button("Dismiss") { appState.chatError = nil }.buttonStyle(.link)
                }
                .font(.caption)
                .foregroundStyle(Theme.danger)
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(Theme.danger.opacity(0.1))
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .bottom, spacing: 10) {
                TextField("Message Arthur…", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...8)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.border))
                    .onSubmit { Task { await send() } }

                Button { Task { await send() } } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Theme.accentDeep, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isSending)
                }
                Text("Return to send · Option-Return for a new line")
                    .font(.caption2).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 12)
        }
    }

    private func send() async {
        let message = draft
        draft = ""
        await appState.send(message)
    }

    private var emptyState: some View {
        ContentUnavailableView("Start a conversation", systemImage: "bubble.left.and.bubble.right", description: Text("Ask Arthur anything. This preview uses a local mock response."))
            .frame(maxWidth: .infinity, minHeight: 280)
    }

    /// Static preview of the "thinking" state.
    private var thinkingRow: some View {
        HStack(spacing: 10) {
            AssistantAvatar()
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(Theme.accent.opacity(0.6)).frame(width: 7, height: 7)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Spacer()
        }
    }
}

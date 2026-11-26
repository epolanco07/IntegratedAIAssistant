import Foundation
import Observation

@MainActor @Observable
final class AppState {
    var selection: SidebarItem = .dashboard
    var conversations: [Conversation] = [Conversation(title: "Planning my week", messages: ChatMessage.samples)]
    var selectedConversationID: UUID?
    var connectionStatus: BackendConnectionStatus = .disconnected
    var isSending = false
    var chatError: String?
    private let chatService: any ChatService

    init(chatService: any ChatService) {
        self.chatService = chatService
        selectedConversationID = conversations.first?.id
    }

    var selectedConversation: Conversation? { conversations.first { $0.id == selectedConversationID } }

    func createConversation() {
        let conversation = Conversation(title: "New conversation")
        conversations.insert(conversation, at: 0)
        selectedConversationID = conversation.id
        selection = .chat
    }

    func selectConversation(_ id: UUID) { selectedConversationID = id; selection = .chat }

    @discardableResult
    func send(_ draft: String) async -> ChatMessage? {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let id = selectedConversationID else { return nil }
        append(ChatMessage(role: .user, text: text), to: id)
        isSending = true; chatError = nil
        defer { isSending = false }
        do {
            let reply = try await chatService.send(text, in: id)
            append(reply, to: id)
            return reply
        }
        catch { chatError = error.localizedDescription }
        return nil
    }

    private func append(_ message: ChatMessage, to id: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == id }) else { return }
        conversations[index].messages.append(message)
        conversations[index].updatedAt = .now
        if conversations[index].title == "New conversation", message.role == .user {
            conversations[index].title = String(message.text.prefix(40))
        }
    }
}

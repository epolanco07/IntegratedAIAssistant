import Foundation
import Observation

@MainActor @Observable
final class AppState {
    var selection: SidebarItem = .dashboard
    // Start with a real empty thread. Sample messages must never become part
    // of Arthur's visible chat or backend conversation context.
    var conversations: [Conversation] = [Conversation(title: "New conversation")]
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
            let response = try await chatService.send(text, in: id)
            apply(response.commands)
            append(response.message, to: id)
            return response.message
        }
        catch { chatError = error.localizedDescription }
        return nil
    }

    private func apply(_ commands: [AppControlCommand]) {
        for command in commands where command.action == "set_speaking_speed" {
            let rate: Double
            switch command.value {
            case "slow": rate = 0.34
            case "fast": rate = 0.58
            default: rate = AudioConfiguration.defaultSpeechRate
            }
            UserDefaults.standard.set(rate, forKey: AudioConfiguration.speechRateKey)
        }
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

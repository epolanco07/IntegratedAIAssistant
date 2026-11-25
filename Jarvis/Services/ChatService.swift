import Foundation

protocol ChatService: Sendable {
    func send(_ text: String, in conversationID: UUID) async throws -> ChatMessage
}

enum ChatServiceError: LocalizedError {
    case emptyMessage
    case unavailable

    var errorDescription: String? {
        switch self {
        case .emptyMessage: "Enter a message before sending."
        case .unavailable: "The assistant service is unavailable."
        }
    }
}

/// Development-only implementation. Swap this at the composition root when the backend is available.
struct MockChatService: ChatService {
    func send(_ text: String, in conversationID: UUID) async throws -> ChatMessage {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { throw ChatServiceError.emptyMessage }
        try await Task.sleep(for: .milliseconds(500))
        return ChatMessage(role: .assistant, text: "This is a local preview response to: \(message)\n\nConnect the FastAPI backend to enable assistant reasoning and authorized tools.")
    }
}

import Foundation

protocol ChatService: Sendable {
    func send(_ text: String, in conversationID: UUID) async throws -> AssistantReply
}

enum ChatServiceError: LocalizedError {
    case emptyMessage
    case unavailable
    case server(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .emptyMessage: "Enter a message before sending."
        case .unavailable: "The assistant service is unavailable."
        case .server(let message): message
        case .invalidResponse: "Arthur returned an unreadable response."
        }
    }
}

/// Sends chat messages to Arthur's FastAPI backend running only on this Mac.
struct HTTPChatService: ChatService {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func send(_ text: String, in conversationID: UUID) async throws -> AssistantReply {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { throw ChatServiceError.emptyMessage }

        var request = URLRequest(url: baseURL.appending(path: "chat"))
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ChatRequest(
                message: message,
                conversationID: conversationID.uuidString,
                timezone: TimeZone.current.identifier
            )
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ChatServiceError.unavailable
        }

        if !(200...299).contains(http.statusCode) {
            if let failure = try? JSONDecoder().decode(BackendFailure.self, from: data) {
                throw ChatServiceError.server(failure.detail)
            }
            throw ChatServiceError.unavailable
        }

        guard let reply = try? JSONDecoder().decode(ChatResponse.self, from: data) else {
            throw ChatServiceError.invalidResponse
        }
        return AssistantReply(
            message: ChatMessage(role: .assistant, text: reply.reply),
            commands: reply.commands
        )
    }
}

private struct ChatRequest: Encodable {
    let message: String
    let conversationID: String
    let timezone: String

    enum CodingKeys: String, CodingKey {
        case message
        case conversationID = "conversation_id"
        case timezone
    }
}

private struct ChatResponse: Decodable {
    let reply: String
    let commands: [AppControlCommand]
}

private struct BackendFailure: Decodable {
    let detail: String
}

struct AppControlCommand: Decodable, Sendable {
    let action: String
    let value: String
}

struct AssistantReply: Sendable {
    let message: ChatMessage
    let commands: [AppControlCommand]
}

/// Development-only implementation. Swap this at the composition root when the backend is available.
struct MockChatService: ChatService {
    func send(_ text: String, in conversationID: UUID) async throws -> AssistantReply {
        let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { throw ChatServiceError.emptyMessage }
        try await Task.sleep(for: .milliseconds(500))
        return AssistantReply(
            message: ChatMessage(role: .assistant, text: "This is a local preview response to: \(message)\n\nConnect the FastAPI backend to enable assistant reasoning and authorized tools."),
            commands: []
        )
    }
}

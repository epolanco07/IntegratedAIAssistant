import Foundation

enum MessageRole: String, Codable, Sendable {
    case user, assistant, system
}

struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let role: MessageRole
    let text: String
    let createdAt: Date

    init(id: UUID = UUID(), role: MessageRole, text: String, createdAt: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }

    var isUser: Bool { role == .user }
    var time: String { createdAt.formatted(date: .omitted, time: .shortened) }

    static let samples = [
        ChatMessage(role: .user, text: "What should I focus on this week?"),
        ChatMessage(role: .assistant, text: "This is a sample reply. Once the assistant is connected, I'll be able to look at your calendar and deadlines and suggest priorities."),
        ChatMessage(role: .user, text: "Can you draft a polite follow-up email?\nKeep it short."),
        ChatMessage(role: .assistant, text: "Another sample reply. Anything that sends or changes something will ask for your confirmation first.")
    ]
}

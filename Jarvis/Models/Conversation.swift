import Foundation

struct Conversation: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var updatedAt: Date

    init(id: UUID = UUID(), title: String, messages: [ChatMessage] = [], updatedAt: Date = .now) {
        self.id = id; self.title = title; self.messages = messages; self.updatedAt = updatedAt
    }
}

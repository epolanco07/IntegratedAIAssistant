import Foundation

protocol VoiceService: Sendable {
    func startSession() async throws
    func endSession() async
}

enum VoiceServiceError: LocalizedError {
    case backendRequired
    var errorDescription: String? { "Voice conversation requires a connected backend service." }
}

struct OfflineVoiceService: VoiceService {
    func startSession() async throws { throw VoiceServiceError.backendRequired }
    func endSession() async { }
}

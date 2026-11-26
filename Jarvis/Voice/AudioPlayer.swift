@preconcurrency import AVFoundation
import Combine
import Foundation

/// Plays Arthur's locally generated Kokoro voice audio.
@MainActor
final class AudioPlayer: NSObject, ObservableObject, @preconcurrency AVAudioPlayerDelegate {
    @Published private(set) var isSpeaking = false
    var onStarted: (@MainActor () -> Void)?
    var onFinished: (@MainActor () -> Void)?
    private var player: AVAudioPlayer?
    private let endpoint = URL(string: "http://127.0.0.1:8000/speech")!

    func speak(_ text: String) async {
        stop()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSpeaking = true
        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 90
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(
                SpeechRequest(text: text, speed: kokoroSpeed)
            )

            let (audioData, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer.delegate = self
            player = audioPlayer
            audioPlayer.prepareToPlay()
            guard audioPlayer.play() else { throw PlaybackError.couldNotStart }
            onStarted?()
        } catch is CancellationError {
            isSpeaking = false
        } catch {
            print("Arthur speech playback failed: \(error.localizedDescription)")
            isSpeaking = false
            onFinished?()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isSpeaking = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully _: Bool) {
        guard self.player === player else { return }
        self.player = nil
        isSpeaking = false
        onFinished?()
    }

    private struct SpeechRequest: Encodable {
        let text: String
        let speed: Double
    }

    /// Maps the existing UI's native-speech-rate range onto Kokoro's natural
    /// speaking-speed range, keeping the Settings slider and agent command live.
    private var kokoroSpeed: Double {
        let nativeRate = Double(AudioConfiguration.preferredSpeechRate)
        return min(max(0.96 + (nativeRate - AudioConfiguration.defaultSpeechRate) * 1.3, 0.72), 1.18)
    }

    private enum PlaybackError: LocalizedError {
        case couldNotStart
        var errorDescription: String? { "Arthur could not start local audio playback." }
    }
}

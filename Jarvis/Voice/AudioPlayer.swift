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
    private var wakeSignalPlayer: AVAudioPlayer?
    private let endpoint = URL(string: "http://127.0.0.1:8000/speech")!

    func speak(_ text: String) async {
        stop()
        let spokenText = speechText(from: text)
        guard !spokenText.isEmpty else { return }
        isSpeaking = true
        do {
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.timeoutInterval = 90
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(
                SpeechRequest(text: spokenText, speed: kokoroSpeed)
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

    /// A quiet, rising local chirp confirms that Arthur heard a direct call
    /// before the agent has finished preparing its reply.
    func playWakeSignal() {
        do {
            let tone = try AVAudioPlayer(data: Self.risingHumWAV())
            tone.volume = 0.24
            tone.prepareToPlay()
            wakeSignalPlayer = tone
            tone.play()
        } catch {
            print("Arthur wake signal failed: \(error.localizedDescription)")
        }
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

    /// Arthur's replies may contain Markdown intended for the chat surface.
    /// Give Kokoro plain speech, preserving arithmetic as spoken multiplication.
    private func speechText(from text: String) -> String {
        let bulletPattern = "(?m)^\\s*[-*]\\s+"
        let range = NSRange(text.startIndex..., in: text)
        let withoutBullets: String
        if let expression = try? NSRegularExpression(pattern: bulletPattern) {
            withoutBullets = expression.stringByReplacingMatches(
                in: text, range: range, withTemplate: ""
            )
        } else {
            withoutBullets = text
        }

        return withoutBullets
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "*", with: " times ")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private enum PlaybackError: LocalizedError {
        case couldNotStart
        var errorDescription: String? { "Arthur could not start local audio playback." }
    }

    private static func risingHumWAV() -> Data {
        let sampleRate = 44_100
        let duration = 0.24
        let sampleCount = Int(Double(sampleRate) * duration)
        var samples = [Int16]()
        samples.reserveCapacity(sampleCount)
        var phase = 0.0

        for index in 0..<sampleCount {
            let progress = Double(index) / Double(sampleCount)
            let frequency = 260.0 + (progress * 520.0)
            phase += 2 * Double.pi * frequency / Double(sampleRate)
            let envelope = sin(Double.pi * min(progress * 2.6, 1.0)) * (1.0 - max(0, progress - 0.72) / 0.28)
            let waveform = (sin(phase) + 0.16 * sin(phase * 2.0)) * envelope * 0.30
            samples.append(Int16(max(-1, min(1, waveform)) * Double(Int16.max)))
        }

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        wav.appendLittleEndian(UInt32(36 + samples.count * MemoryLayout<Int16>.size))
        wav.append("WAVEfmt ".data(using: .ascii)!)
        wav.appendLittleEndian(UInt32(16))
        wav.appendLittleEndian(UInt16(1))
        wav.appendLittleEndian(UInt16(1))
        wav.appendLittleEndian(UInt32(sampleRate))
        wav.appendLittleEndian(UInt32(sampleRate * MemoryLayout<Int16>.size))
        wav.appendLittleEndian(UInt16(MemoryLayout<Int16>.size))
        wav.appendLittleEndian(UInt16(16))
        wav.append("data".data(using: .ascii)!)
        wav.appendLittleEndian(UInt32(samples.count * MemoryLayout<Int16>.size))
        samples.withUnsafeBytes { wav.append(contentsOf: $0) }
        return wav
    }
}

private extension Data {
    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { append(contentsOf: $0) }
    }
}

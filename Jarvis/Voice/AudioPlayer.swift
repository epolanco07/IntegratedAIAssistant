@preconcurrency import AVFoundation
import Combine

@MainActor
final class AudioPlayer: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false
    var onFinished: (@MainActor () -> Void)?
    private let synthesizer = AVSpeechSynthesizer()

    override init() { super.init(); synthesizer.delegate = self }

    func speak(_ text: String) {
        stop()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AudioConfiguration.preferredSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: AudioConfiguration.preferredLocaleIdentifier)
        synthesizer.speak(utterance)
    }

    func stop() { synthesizer.stopSpeaking(at: .immediate); isSpeaking = false }
    func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) { isSpeaking = true }
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        isSpeaking = false
        onFinished?()
    }
    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) { isSpeaking = false }
}

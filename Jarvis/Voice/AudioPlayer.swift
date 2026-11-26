@preconcurrency import AVFoundation
import Combine

@MainActor
final class AudioPlayer: NSObject, ObservableObject, @preconcurrency AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false
    var onStarted: (@MainActor () -> Void)?
    var onFinished: (@MainActor () -> Void)?
    private let synthesizer = AVSpeechSynthesizer()

    override init() { super.init(); synthesizer.delegate = self }

    func speak(_ text: String) {
        // Do not send a cancellation to an idle synthesizer immediately before
        // queuing new speech; on some macOS audio routes that can cancel the
        // new utterance as well.
        if synthesizer.isSpeaking { stop() }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AudioConfiguration.preferredSpeechRate
        utterance.voice = AVSpeechSynthesisVoice(language: AudioConfiguration.preferredLocaleIdentifier)
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }
    func speechSynthesizer(_: AVSpeechSynthesizer, didStart _: AVSpeechUtterance) {
        isSpeaking = true
        onStarted?()
    }
    func speechSynthesizer(_: AVSpeechSynthesizer, didFinish _: AVSpeechUtterance) {
        isSpeaking = false
        onFinished?()
    }
    func speechSynthesizer(_: AVSpeechSynthesizer, didCancel _: AVSpeechUtterance) { isSpeaking = false }
}

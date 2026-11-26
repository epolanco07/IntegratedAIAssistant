import Foundation
import Combine

@MainActor
final class VoiceManager: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isProcessing = false
    @Published private(set) var recorderState: AudioRecorder.State = .idle
    @Published private(set) var isAwaitingFollowUp = false
    let recorder = AudioRecorder()
    let player = AudioPlayer()
    /// The app assigns this to route a finished spoken phrase to Arthur.
    var onFinalTranscript: (@MainActor (_ transcript: String) -> Void)?
    private var subscriptions = Set<AnyCancellable>()
    private var pauseTask: Task<Void, Never>?
    private var manuallyPaused = false
    private var lastSubmittedTranscript = ""
    private let endOfTurnSilence: Duration = .seconds(2)

    init() {
        recorder.$state
            .sink { [weak self] state in self?.recorderState = state }
            .store(in: &subscriptions)
        recorder.onTranscription = { [weak self] text, _ in
            self?.receiveTranscription(text)
        }
        player.onFinished = { [weak self] in
            // While Arthur is still working, his short acknowledgement must
            // not reopen the microphone and accidentally form a new turn.
            guard let self, !self.manuallyPaused, !self.isProcessing else { return }
            Task { await self.startContinuousListening() }
        }
    }

    func startContinuousListening() async {
        // Never open the microphone while Arthur is speaking. This prevents
        // the recognizer from hearing Arthur's own synthesized response.
        guard recorderState != .recording, !player.isSpeaking else { return }
        manuallyPaused = false
        transcript = ""
        lastSubmittedTranscript = ""
        await recorder.start()
    }

    func pauseListening() {
        manuallyPaused = true
        pauseTask?.cancel()
        recorder.stop()
    }

    func interrupt() {
        // A deliberate interruption keeps listening paused until the user
        // resumes it, preventing a feedback loop from trailing output audio.
        player.stop()
        pauseListening()
    }

    func speak(_ text: String) async {
        pauseTask?.cancel()
        recorder.stop()
        transcript = ""
        await player.speak(text)
    }

    func setProcessing(_ processing: Bool) { isProcessing = processing }
    func setAwaitingFollowUp(_ awaiting: Bool) { isAwaitingFollowUp = awaiting }

    private func receiveTranscription(_ text: String) {
        transcript = text
        pauseTask?.cancel()

        // Apple can mark partial phrases as final in the middle of a longer
        // instruction. Wait for stable silence instead, so normal pauses do
        // not make Arthur answer over the user.
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: self?.endOfTurnSilence ?? .seconds(2))
            guard !Task.isCancelled else { return }
            self?.submitCurrentPhrase()
        }
    }

    private func submitCurrentPhrase() {
        let phrase = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard recorderState == .recording,
              !phrase.isEmpty,
              phrase != lastSubmittedTranscript else { return }

        // Background speech stays local until the user addresses Arthur. A
        // follow-up to Arthur's own question is the intentional exception.
        guard isAwaitingFollowUp || containsWakeWord(phrase) else {
            restartWakeWordListening()
            return
        }

        lastSubmittedTranscript = phrase
        isAwaitingFollowUp = false
        recorder.stop()
        isProcessing = true
        player.playWakeSignal()
        onFinalTranscript?(phrase)
    }

    private func restartWakeWordListening() {
        transcript = ""
        lastSubmittedTranscript = ""
        recorder.resetRecognition()
    }

    private func containsWakeWord(_ text: String) -> Bool {
        let phraseWords = words(in: text)
        let wakeVariants: Set<String> = ["arthur", "author"]
        // Speech recognition can retain a few earlier background words in the
        // same partial transcript. Recognize an actual call such as "hey
        // Arthur" wherever it appears, rather than requiring it to be word 1.
        // Ordinary mentions ("my assistant named Arthur") still do not match.
        let leadInWords: Set<String> = [
            "hey", "hi", "hello", "okay", "ok", "yo", "um", "uh",
            "there", "please", "sorry",
        ]
        for wakeIndex in phraseWords.indices where wakeVariants.contains(phraseWords[wakeIndex]) {
            if wakeIndex == 0 { return true }

            let start = max(0, wakeIndex - 3)
            let leadIn = phraseWords[start..<wakeIndex]
            if !leadIn.isEmpty, leadIn.allSatisfy({ leadInWords.contains($0) }) {
                return true
            }
        }
        return false
    }

    private func words(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}

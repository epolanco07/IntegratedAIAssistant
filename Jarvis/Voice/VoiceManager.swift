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
            guard let self, !self.manuallyPaused else { return }
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
        guard let wakeIndex = phraseWords.firstIndex(where: { wakeVariants.contains($0) }), wakeIndex <= 3 else {
            return false
        }

        // "Arthur", "Hey there Arthur", and "Okay Arthur" are direct
        // addresses. A sentence such as "I have an assistant named Arthur"
        // is not, because its lead-in is not a greeting/filler.
        let leadInWords: Set<String> = [
            "hey", "hi", "hello", "okay", "ok", "yo", "um", "uh",
            "there", "please", "sorry",
        ]
        return phraseWords[..<wakeIndex].allSatisfy { leadInWords.contains($0) }
    }

    private func words(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}

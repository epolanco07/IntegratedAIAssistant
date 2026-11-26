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
    private var monitoringBargeIn = false
    private var spokenPhraseWords: [String] = []

    init() {
        recorder.$state
            .sink { [weak self] state in self?.recorderState = state }
            .store(in: &subscriptions)
        recorder.onTranscription = { [weak self] text, _ in
            self?.receiveTranscription(text)
        }
        player.onFinished = { [weak self] in
            guard let self, !self.manuallyPaused else { return }
            self.stopBargeInMonitor()
            Task { await self.startContinuousListening() }
        }
        player.onStarted = { [weak self] in
            self?.startBargeInMonitor()
        }
    }

    func startContinuousListening() async {
        // Never open the microphone while Arthur is speaking. This prevents
        // the recognizer from hearing Arthur's own synthesized response.
        guard recorderState != .recording, !player.isSpeaking else { return }
        manuallyPaused = false
        monitoringBargeIn = false
        transcript = ""
        lastSubmittedTranscript = ""
        await recorder.start()
    }

    func pauseListening() {
        manuallyPaused = true
        monitoringBargeIn = false
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
        monitoringBargeIn = false
        spokenPhraseWords = words(in: text)
        player.speak(text)
    }

    func setProcessing(_ processing: Bool) { isProcessing = processing }
    func setAwaitingFollowUp(_ awaiting: Bool) { isAwaitingFollowUp = awaiting }

    private func receiveTranscription(_ text: String) {
        if monitoringBargeIn {
            handleBargeIn(text)
            return
        }
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

    private func handleBargeIn(_ text: String) {
        let candidateWords = words(in: text)
        let echoedWordCount = matchingPrefixLength(candidateWords, spokenPhraseWords)
        let novelWords = Array(candidateWords.dropFirst(echoedWordCount))
        let interruptionWords: Set<String> = ["stop", "wait", "pause", "quiet", "cancel", "enough"]
        let isExplicitInterruption = !interruptionWords.isDisjoint(with: Set(candidateWords))

        // Require either a clear interruption word or a short new phrase.
        // This filters the microphone pickup of Arthur's own voice while still
        // letting the user naturally take over the conversation.
        guard isExplicitInterruption || novelWords.count >= 3 else { return }

        monitoringBargeIn = false
        pauseTask?.cancel()
        player.stop()
        recorder.stop()

        let phrase = novelWords.joined(separator: " ")
        guard !phrase.isEmpty else { return }
        transcript = phrase
        isProcessing = true
        onFinalTranscript?(phrase)
    }

    private func stopBargeInMonitor() {
        guard monitoringBargeIn else { return }
        monitoringBargeIn = false
        recorder.stop()
    }

    private func startBargeInMonitor() {
        guard player.isSpeaking, !manuallyPaused else { return }
        monitoringBargeIn = true
        // This monitor is only for barge-in. It never creates a normal voice
        // turn during output unless a new user phrase is recognized.
        Task { [weak self] in
            // Give macOS output processing a moment to settle before opening
            // the input path for a spoken interruption.
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, self.player.isSpeaking, self.monitoringBargeIn else { return }
            await self.recorder.start()
        }
    }

    private func matchingPrefixLength(_ candidate: [String], _ expected: [String]) -> Int {
        var matchCount = 0
        for (candidateWord, expectedWord) in zip(candidate, expected) {
            guard candidateWord == expectedWord else { break }
            matchCount += 1
        }
        return matchCount
    }

    private func restartWakeWordListening() {
        transcript = ""
        recorder.stop()
        Task { await startContinuousListening() }
    }

    private func containsWakeWord(_ text: String) -> Bool {
        let phraseWords = words(in: text)
        guard let wakeIndex = phraseWords.firstIndex(of: "arthur"), wakeIndex <= 2 else {
            return false
        }

        // "Arthur", "Hey Arthur", and "Okay Arthur" are direct addresses.
        // A sentence such as "I have an assistant named Arthur" is not.
        let allowedLeadIns: Set<String> = ["hey", "hi", "hello", "okay", "ok", "yo", "um", "uh"]
        return phraseWords[..<wakeIndex].allSatisfy { allowedLeadIns.contains($0) }
    }

    private func words(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
    }
}

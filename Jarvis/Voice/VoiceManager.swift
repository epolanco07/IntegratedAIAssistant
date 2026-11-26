import Foundation
import Combine

@MainActor
final class VoiceManager: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isProcessing = false
    @Published private(set) var recorderState: AudioRecorder.State = .idle
    let recorder = AudioRecorder()
    let player = AudioPlayer()
    /// The app assigns this to route a finished spoken phrase to Arthur.
    var onFinalTranscript: (@MainActor (_ transcript: String) -> Void)?
    private var subscriptions = Set<AnyCancellable>()
    private var pauseTask: Task<Void, Never>?
    private var manuallyPaused = false
    private var lastSubmittedTranscript = ""

    init() {
        recorder.$state
            .sink { [weak self] state in self?.recorderState = state }
            .store(in: &subscriptions)

        recorder.onTranscription = { [weak self] text, isFinal in
            self?.receiveTranscription(text, isFinal: isFinal)
        }
        player.onFinished = { [weak self] in
            guard let self, !self.manuallyPaused else { return }
            Task { await self.startContinuousListening() }
        }
    }

    func startContinuousListening() async {
        guard recorderState != .recording else { return }
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
        player.stop()
        pauseListening()
    }

    func speak(_ text: String) {
        pauseTask?.cancel()
        recorder.stop()
        player.speak(text)
    }

    func setProcessing(_ processing: Bool) { isProcessing = processing }

    private func receiveTranscription(_ text: String, isFinal: Bool) {
        transcript = text
        pauseTask?.cancel()

        if isFinal {
            submitCurrentPhrase()
            return
        }

        // Apple Speech sends partial results while the user is talking. A
        // short quiet period marks the end of a natural spoken turn.
        pauseTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.1))
            guard !Task.isCancelled else { return }
            self?.submitCurrentPhrase()
        }
    }

    private func submitCurrentPhrase() {
        let phrase = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard recorderState == .recording,
              !phrase.isEmpty,
              phrase != lastSubmittedTranscript else { return }

        lastSubmittedTranscript = phrase
        recorder.stop()
        isProcessing = true
        onFinalTranscript?(phrase)
    }
}

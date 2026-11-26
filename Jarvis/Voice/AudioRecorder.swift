import AVFoundation
import Combine
import Speech

@MainActor
final class AudioRecorder: ObservableObject {
    enum State: Equatable { case idle, recording, denied, failed(String) }
    @Published private(set) var state: State = .idle
    @Published private(set) var transcript = ""

    /// Called with live transcription and whether the recognizer considers the
    /// current phrase final. VoiceManager decides when a natural pause means
    /// the phrase should be sent to Arthur.
    var onTranscription: (@MainActor (_ text: String, _ isFinal: Bool) -> Void)?

    private let engine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func start() async {
        let authorized: Bool
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            authorized = true
        case .notDetermined:
            authorized = await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            authorized = false
        @unknown default:
            authorized = false
        }
        guard authorized else {
            state = .failed("Microphone access was denied. Enable Arthur in Privacy & Security > Microphone.")
            return
        }

        let speechAuthorized = await Self.requestSpeechAuthorization()
        guard speechAuthorized else {
            state = .failed("Speech Recognition access was denied. Enable Arthur in Privacy & Security > Speech Recognition.")
            return
        }
        guard let recognizer, recognizer.isAvailable else {
            state = .failed("Speech recognition is currently unavailable.")
            return
        }

        do {
            transcript = ""
            let input = engine.inputNode
            installRecognitionTask(on: input, recognizer: recognizer)
            engine.prepare()
            try engine.start()
            state = .recording
        } catch { state = .failed(error.localizedDescription) }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        if state == .recording { state = .idle }
    }

    /// Clears recognized background speech without interrupting microphone
    /// capture. This keeps wake-word listening continuous between phrases.
    func resetRecognition() {
        guard state == .recording, let recognizer, recognizer.isAvailable else { return }
        transcript = ""
        installRecognitionTask(on: engine.inputNode, recognizer: recognizer)
    }

    private func installRecognitionTask(on input: AVAudioInputNode, recognizer: SFSpeechRecognizer) {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // A canceled, superseded request reports an error after the
                // next request is already active; ignore that stale callback.
                guard self.recognitionRequest === request else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.transcript = text
                    self.onTranscription?(text, result.isFinal)
                }
                if let error, self.state == .recording {
                    self.state = .failed(error.localizedDescription)
                }
            }
        }

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1_024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
    }

    private static func requestSpeechAuthorization() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .notDetermined:
            let status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status)
                }
            }
            return status == .authorized
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

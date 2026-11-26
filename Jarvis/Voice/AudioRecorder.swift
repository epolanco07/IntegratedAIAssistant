import AVFoundation
import Combine

@MainActor
final class AudioRecorder: ObservableObject {
    enum State: Equatable { case idle, recording, denied, failed(String) }
    @Published private(set) var state: State = .idle
    private let engine = AVAudioEngine()

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
        guard authorized else { state = .denied; return }
        do {
            let input = engine.inputNode
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1_024, format: input.outputFormat(forBus: 0)) { _, _ in
                // Audio frames will be streamed to the backend in a future VoiceService implementation.
            }
            engine.prepare()
            try engine.start()
            state = .recording
        } catch { state = .failed(error.localizedDescription) }
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        if state == .recording { state = .idle }
    }
}

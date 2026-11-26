import Foundation
import Combine

@MainActor
final class VoiceManager: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isProcessing = false
    @Published private(set) var recorderState: AudioRecorder.State = .idle
    let recorder = AudioRecorder()
    let player = AudioPlayer()
    private var subscriptions = Set<AnyCancellable>()

    init() {
        recorder.$state
            .sink { [weak self] state in self?.recorderState = state }
            .store(in: &subscriptions)
    }

    func startContinuousListening() async {
        guard recorderState != .recording else { return }
        await recorder.start()
    }

    func pauseListening() { recorder.stop() }
    func interrupt() { player.stop() }
}

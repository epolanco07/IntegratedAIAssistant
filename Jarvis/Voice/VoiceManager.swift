import Foundation
import Combine

@MainActor
final class VoiceManager: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isProcessing = false
    let recorder = AudioRecorder()
    let player = AudioPlayer()

    func startContinuousListening() async {
        guard recorder.state != .recording else { return }
        await recorder.start()
    }

    func pauseListening() { recorder.stop() }
    func interrupt() { player.stop() }
}

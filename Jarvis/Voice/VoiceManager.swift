import Foundation
import Combine

@MainActor
final class VoiceManager: ObservableObject {
    @Published private(set) var transcript = ""
    @Published private(set) var isProcessing = false
    let recorder = AudioRecorder()
    let player = AudioPlayer()

    func beginPushToTalk() async { await recorder.start() }
    func endPushToTalk() { recorder.stop() }
    func interrupt() { player.stop() }
}

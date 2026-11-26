import Foundation

enum AudioConfiguration {
    static let preferredLocaleIdentifier = "en-GB"
    static let defaultSpeechRate: Double = 0.46
    static let speechRateKey = "arthur.speechRate"

    static var preferredSpeechRate: Float {
        let storedRate = UserDefaults.standard.object(forKey: speechRateKey) as? NSNumber
        return Float(storedRate?.doubleValue ?? defaultSpeechRate)
    }
}

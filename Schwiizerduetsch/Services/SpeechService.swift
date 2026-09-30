import AVFoundation

/// Reads phrases aloud with the system voice. The voice is a *German* voice, so we
/// respell some Swiss sounds (e.g. word-initial «ch» → «kh») to get closer to the dialect.
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?

    override init() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let swiss = voices.filter { $0.language == "de-CH" }
        let german = voices.filter { $0.language.hasPrefix("de") }
        let pool = swiss.isEmpty ? german : swiss
        voice = pool.max(by: { $0.quality.rawValue < $1.quality.rawValue }) ?? AVSpeechSynthesisVoice(language: "de-DE")
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func speak(_ text: String, slow: Bool = false) {
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: Self.respell(text))
        u.voice = voice
        u.rate = slow ? 0.34 : 0.44
        u.pitchMultiplier = 1.0
        u.preUtteranceDelay = 0.05
        synth.speak(u)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }

    static func respell(_ text: String) -> String {
        var words: [String] = []
        for word in text.split(separator: " ", omittingEmptySubsequences: true) {
            var w = String(word)
            if w.lowercased().hasPrefix("ch") {
                w = (w.first!.isUppercase ? "Kh" : "kh") + w.dropFirst(2)
            }
            words.append(w)
        }
        return words.joined(separator: " ")
    }
}

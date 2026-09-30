import AVFoundation

/// Plays a phrase. Order of preference:
/// 1. A bundled recording `Audio/<phraseID>.(mp3|m4a|wav)` (real Swiss German speaker)
/// 2. The best installed German system voice with a Swiss-style respelling (approximation)
final class SpeechService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?
    private var player: AVAudioPlayer?
    private let idByText: [String: String]

    override init() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let swiss = voices.filter { $0.language == "de-CH" }
        let german = voices.filter { $0.language.hasPrefix("de") }
        let pool = swiss.isEmpty ? german : swiss
        voice = pool.max(by: { $0.quality.rawValue < $1.quality.rawValue }) ?? AVSpeechSynthesisVoice(language: "de-DE")
        idByText = Dictionary(Curriculum.allPhrases.map { ($0.ch, $0.id) }, uniquingKeysWith: { a, _ in a })
        super.init()
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    /// True when a real recording exists for this phrase text.
    func hasRecording(for text: String) -> Bool { recordingURL(for: text) != nil }

    private func recordingURL(for text: String) -> URL? {
        guard let id = idByText[text] else { return nil }
        for ext in ["mp3", "m4a", "wav"] {
            if let url = Bundle.main.url(forResource: id, withExtension: ext, subdirectory: "Audio") { return url }
        }
        return nil
    }

    func speak(_ text: String, slow: Bool = false) {
        try? AVAudioSession.sharedInstance().setActive(true)
        synth.stopSpeaking(at: .immediate)
        player?.stop()
        if let url = recordingURL(for: text), let p = try? AVAudioPlayer(contentsOf: url) {
            p.enableRate = true
            p.rate = slow ? 0.7 : 1.0
            p.prepareToPlay()
            p.play()
            player = p
            return
        }
        let u = AVSpeechUtterance(string: Self.respell(text))
        u.voice = voice
        u.rate = slow ? 0.32 : 0.42
        u.pitchMultiplier = 0.98
        u.preUtteranceDelay = 0.05
        synth.speak(u)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        player?.stop()
    }

    /// Respells Swiss German so a *German* voice lands closer to the dialect:
    /// - word-initial «ch» is a hard «kch»  → «kh»
    /// - Swiss «s» before a vowel is voiceless (German voices voice it) → «ß»
    /// - «ue/üe/ie» are real diphthongs (u-e, ü-e, i-e) → separated with a soft glide
    static func respell(_ text: String) -> String {
        let vowels = Set("aeiouäöüAEIOUÄÖÜ")
        var words: [String] = []
        for word in text.split(separator: " ", omittingEmptySubsequences: true) {
            var w = String(word)
            if w.lowercased().hasPrefix("ch") {
                w = (w.first!.isUppercase ? "Kh" : "kh") + w.dropFirst(2)
            } else if let f = w.first, f == "s" || f == "S", w.count > 1, vowels.contains(w[w.index(after: w.startIndex)]) {
                w = "ß" + w.dropFirst()
            }
            w = w.replacingOccurrences(of: "üe", with: "ü-e")
                 .replacingOccurrences(of: "ue", with: "u-e")
                 .replacingOccurrences(of: "ie", with: "i-e")
            words.append(w)
        }
        return words.joined(separator: " ")
    }
}

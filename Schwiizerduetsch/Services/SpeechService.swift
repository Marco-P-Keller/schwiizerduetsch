import AVFoundation

/// Plays real Swiss German recordings. There is deliberately *no* computer-voice fallback:
/// a German synthesizer never sounds like the dialect. Audio UI only appears for phrases
/// that have a bundled recording `Audio/<phraseID>.(mp3|m4a|wav)`.
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()
    private var player: AVAudioPlayer?
    private let idByText: [String: String]

    /// True if at least one recording ships with the app.
    let anyRecordings: Bool

    override init() {
        idByText = Dictionary(Curriculum.allPhrases.map { ($0.ch, $0.id) }, uniquingKeysWith: { a, _ in a })
        let exts = ["mp3", "m4a", "wav"]
        anyRecordings = exts.contains { !(Bundle.main.urls(forResourcesWithExtension: $0, subdirectory: "Audio") ?? []).isEmpty }
        super.init()
        if anyRecordings {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        }
    }

    func hasRecording(for text: String) -> Bool { recordingURL(for: text) != nil }

    private func recordingURL(for text: String) -> URL? {
        guard anyRecordings, let id = idByText[text] else { return nil }
        for ext in ["mp3", "m4a", "wav"] {
            if let url = Bundle.main.url(forResource: id, withExtension: ext, subdirectory: "Audio") { return url }
        }
        return nil
    }

    func speak(_ text: String, slow: Bool = false) {
        guard let url = recordingURL(for: text), let p = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setActive(true)
        player?.stop()
        p.enableRate = true
        p.rate = slow ? 0.7 : 1.0
        p.prepareToPlay()
        p.play()
        player = p
    }

    func stop() { player?.stop() }
}

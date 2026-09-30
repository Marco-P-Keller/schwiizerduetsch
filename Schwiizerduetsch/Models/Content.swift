import SwiftUI

struct Phrase: Identifiable, Hashable {
    let id: String
    let ch: String
    let de: String
    let en: String
    var noteDE: String? = nil
    var noteEN: String? = nil

    var translation: String { AppLanguage.current == .de ? de : en }
    var note: String? { AppLanguage.current == .de ? noteDE : noteEN }

    /// Words of the Swiss German sentence (used for the sentence-building exercise).
    var words: [String] { ch.split(separator: " ").map(String.init) }
}

struct Lesson: Identifiable, Hashable {
    let id: String
    let unitID: String
    let index: Int
    let phrases: [Phrase]
}

struct Unit: Identifiable, Hashable {
    let id: String
    let emoji: String
    let titleDE: String
    let titleEN: String
    let subtitleDE: String
    let subtitleEN: String
    let color: Color
    let isFree: Bool
    let phrases: [Phrase]

    var title: String { AppLanguage.current == .de ? titleDE : titleEN }
    var subtitle: String { AppLanguage.current == .de ? subtitleDE : subtitleEN }

    var lessons: [Lesson] {
        // ~6 phrases per lesson, distributed evenly so no lesson is tiny.
        let n = max(1, Int((Double(phrases.count) / 6).rounded()))
        let base = phrases.count / n, extra = phrases.count % n
        var start = 0
        return (0..<n).map { i in
            let size = base + (i < extra ? 1 : 0)
            defer { start += size }
            return Lesson(id: "\(id)-\(i)", unitID: id, index: i, phrases: Array(phrases[start..<start + size]))
        }
    }
}

enum Curriculum {
    static let units: [Unit] = ContentData.build()
    static let allPhrases: [Phrase] = units.flatMap(\.phrases)
    static let allLessons: [Lesson] = units.flatMap(\.lessons)

    static func unit(_ id: String) -> Unit? { units.first { $0.id == id } }
    static func phrase(_ id: String) -> Phrase? { allPhrases.first { $0.id == id } }
    static func lesson(_ id: String) -> Lesson? { allLessons.first { $0.id == id } }

    /// Deterministic "word of the day".
    static func phraseOfTheDay(_ date: Date = .now) -> Phrase {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        let pool = allPhrases.filter { $0.ch.split(separator: " ").count <= 4 }
        return pool[day % pool.count]
    }
}

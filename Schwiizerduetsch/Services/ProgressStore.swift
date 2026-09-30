import SwiftUI

struct Achievement: Identifiable {
    let id: String
    let emoji: String
    let titleDE: String
    let titleEN: String
    let detailDE: String
    let detailEN: String
    let unlocked: Bool
    var title: String { AppLanguage.current == .de ? titleDE : titleEN }
    var detail: String { AppLanguage.current == .de ? detailDE : detailEN }
}

@MainActor
final class ProgressStore: ObservableObject {
    struct State: Codable {
        var onboardingDone = false
        var reason = "move"
        var level = 0
        var dailyGoalXP = 40
        var xp = 0
        var completedLessons: [String] = []
        var activeDays: [String] = []
        var xpByDay: [String: Int] = [:]
        var seenPhrases: [String] = []
        var weak: [String: Int] = [:]
        var favorites: [String] = []
        var language: String? = nil
        var reminderEnabled = false
        var reminderHour = 18
        var reminderMinute = 30
        var lessonsFinished = 0
        var quizBest = 0
        var dialectOpened = false
        var reviewPromptedAtLesson = 0
        var autoplay = true

        /// Tolerant decoding: missing keys (from older app versions) fall back to defaults.
        static func load(_ data: Data) -> State? {
            guard let defaults = try? JSONEncoder().encode(State()),
                  var base = (try? JSONSerialization.jsonObject(with: defaults)) as? [String: Any],
                  let stored = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else { return nil }
            base.merge(stored) { _, new in new }
            guard let merged = try? JSONSerialization.data(withJSONObject: base) else { return nil }
            return try? JSONDecoder().decode(State.self, from: merged)
        }
    }

    @Published var state: State { didSet { save() } }
    private let key = "progress.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: "progress.v1"),
           let s = State.load(data) {
            state = s
        } else {
            state = State()
        }
        AppLanguage.current = language
        #if DEBUG
        applyLaunchArguments()
        #endif
    }

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: Language
    var language: AppLanguage {
        get { state.language.flatMap(AppLanguage.init(rawValue:)) ?? .system }
        set { state.language = newValue.rawValue; AppLanguage.current = newValue }
    }

    // MARK: Days & streak
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date = .now) -> String { dayFormatter.string(from: date) }

    var todayXP: Int { state.xpByDay[Self.dayKey()] ?? 0 }
    var goalProgress: Double { min(1, Double(todayXP) / Double(max(1, state.dailyGoalXP))) }

    var streak: Int {
        let days = Set(state.activeDays)
        var date = Date()
        if !days.contains(Self.dayKey(date)) {
            guard let y = Calendar.current.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = y
        }
        var count = 0
        while days.contains(Self.dayKey(date)) {
            count += 1
            guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }
        return count
    }

    var studiedToday: Bool { state.activeDays.contains(Self.dayKey()) }

    /// Last 7 days (oldest first) with active flag.
    var weekActivity: [(label: String, active: Bool, isToday: Bool)] {
        let days = Set(state.activeDays)
        let cal = Calendar.current
        var symbols = cal.veryShortWeekdaySymbols
        if symbols.count < 7 { symbols = ["S", "M", "D", "M", "D", "F", "S"] }
        return (0..<7).reversed().map { offset in
            let d = cal.date(byAdding: .day, value: -offset, to: Date())!
            let wd = cal.component(.weekday, from: d) - 1
            return (symbols[wd], days.contains(Self.dayKey(d)), offset == 0)
        }
    }

    // MARK: Level
    var level: Int { state.xp / 120 + 1 }
    var levelProgress: Double { Double(state.xp % 120) / 120 }

    // MARK: Lessons
    func isCompleted(_ lesson: Lesson) -> Bool { state.completedLessons.contains(lesson.id) }

    func completedCount(in unit: Unit) -> Int { unit.lessons.filter { isCompleted($0) }.count }

    func progress(of unit: Unit) -> Double {
        let total = unit.lessons.count
        return total == 0 ? 0 : Double(completedCount(in: unit)) / Double(total)
    }

    func isUnitDone(_ unit: Unit) -> Bool { completedCount(in: unit) == unit.lessons.count }

    var completedUnits: Int { Curriculum.units.filter { isUnitDone($0) }.count }

    /// Next lesson the user should take (first incomplete one).
    var nextLesson: Lesson? { Curriculum.allLessons.first { !isCompleted($0) } }

    func finish(lesson: Lesson, xpGained: Int, mistakes: [String: Int]) {
        var s = state
        if !s.completedLessons.contains(lesson.id) { s.completedLessons.append(lesson.id) }
        s.xp += xpGained
        let key = Self.dayKey()
        s.xpByDay[key, default: 0] += xpGained
        if !s.activeDays.contains(key) { s.activeDays.append(key) }
        for p in lesson.phrases where !s.seenPhrases.contains(p.id) { s.seenPhrases.append(p.id) }
        for (id, n) in mistakes { s.weak[id, default: 0] += n }
        for p in lesson.phrases where mistakes[p.id] == nil {
            if let w = s.weak[p.id], w > 0 { s.weak[p.id] = w - 1 }
        }
        s.lessonsFinished += 1
        state = s
    }

    func recordPractice(xp: Int, mistakes: [String: Int]) {
        var s = state
        s.xp += xp
        let key = Self.dayKey()
        s.xpByDay[key, default: 0] += xp
        if !s.activeDays.contains(key) { s.activeDays.append(key) }
        for (id, n) in mistakes { s.weak[id, default: 0] += n }
        state = s
    }

    func clearWeak(_ ids: [String]) {
        var s = state
        for id in ids where mistakesFree(id, in: s) { s.weak[id] = 0 }
        state = s
    }

    private func mistakesFree(_ id: String, in s: State) -> Bool { (s.weak[id] ?? 0) > 0 }

    var learnedPhrases: [Phrase] {
        let ids = Set(state.seenPhrases)
        return Curriculum.allPhrases.filter { ids.contains($0.id) }
    }

    var weakPhrases: [Phrase] {
        state.weak.filter { $0.value > 0 }.keys.compactMap { Curriculum.phrase($0) }
    }

    // MARK: Favorites
    func isFavorite(_ p: Phrase) -> Bool { state.favorites.contains(p.id) }
    func toggleFavorite(_ p: Phrase) {
        if let i = state.favorites.firstIndex(of: p.id) { state.favorites.remove(at: i) }
        else { state.favorites.append(p.id) }
    }

    // MARK: Achievements
    var achievements: [Achievement] {
        let s = state
        return [
            Achievement(id: "first", emoji: "🌱", titleDE: "Erste Lektion", titleEN: "First lesson",
                        detailDE: "Schliesse deine erste Lektion ab.", detailEN: "Finish your first lesson.", unlocked: s.lessonsFinished >= 1 || !s.completedLessons.isEmpty),
            Achievement(id: "streak3", emoji: "🔥", titleDE: "Dranbleiber", titleEN: "Getting warm",
                        detailDE: "3 Tage in Folge gelernt.", detailEN: "Learn 3 days in a row.", unlocked: streak >= 3),
            Achievement(id: "streak7", emoji: "🏅", titleDE: "Wochenheld", titleEN: "Week warrior",
                        detailDE: "7 Tage in Folge gelernt.", detailEN: "Learn 7 days in a row.", unlocked: streak >= 7),
            Achievement(id: "streak30", emoji: "🏆", titleDE: "Eidgenoss", titleEN: "Confederate",
                        detailDE: "30 Tage in Folge gelernt.", detailEN: "Learn 30 days in a row.", unlocked: streak >= 30),
            Achievement(id: "xp250", emoji: "⚡️", titleDE: "250 XP", titleEN: "250 XP",
                        detailDE: "Sammle 250 XP.", detailEN: "Earn 250 XP.", unlocked: s.xp >= 250),
            Achievement(id: "words50", emoji: "📚", titleDE: "50 Ausdrücke", titleEN: "50 phrases",
                        detailDE: "Lerne 50 verschiedene Ausdrücke.", detailEN: "Learn 50 different phrases.", unlocked: s.seenPhrases.count >= 50),
            Achievement(id: "unit", emoji: "🧀", titleDE: "Kapitel geschafft", titleEN: "Chapter done",
                        detailDE: "Schliesse ein ganzes Kapitel ab.", detailEN: "Complete an entire chapter.", unlocked: completedUnits >= 1),
            Achievement(id: "dialect", emoji: "🗺️", titleDE: "Dialekt-Detektiv", titleEN: "Dialect detective",
                        detailDE: "Öffne den Dialekt-Explorer.", detailEN: "Open the dialect explorer.", unlocked: s.dialectOpened),
            Achievement(id: "quiz", emoji: "🇨🇭", titleDE: "Swissness-Check", titleEN: "Swissness check",
                        detailDE: "Mach das «Wie schweizerisch bist du?»-Quiz.", detailEN: "Take the «How Swiss are you?» quiz.", unlocked: s.quizBest > 0),
        ]
    }

    #if DEBUG
    /// Launch argument used to generate App Store screenshots: `-demo` (add `-en` for English).
    private func applyLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-onboarding") {
            var fresh = State()
            fresh.language = args.contains("-en") ? "en" : "de"
            state = fresh
            AppLanguage.current = language
            return
        }
        guard args.contains("-demo") else { return }
        var s = State()
        s.onboardingDone = true
        s.xp = 340
        s.dailyGoalXP = 40
        s.completedLessons = ["hello-0", "hello-1", "intro-0"]
        s.seenPhrases = Curriculum.units.prefix(2).flatMap { $0.phrases }.map { $0.id }
        let cal = Calendar.current
        for off in 0..<6 {
            let d = Self.dayKey(cal.date(byAdding: .day, value: -off, to: Date())!)
            s.activeDays.append(d)
            s.xpByDay[d] = off == 0 ? 25 : 40
        }
        s.dialectOpened = true
        s.quizBest = 8
        s.language = args.contains("-en") ? "en" : "de"
        state = s
        AppLanguage.current = language
    }
    #endif
}

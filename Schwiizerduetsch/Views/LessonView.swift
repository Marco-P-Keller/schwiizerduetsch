import SwiftUI
import StoreKit

enum LessonMode { case lesson, practice }
enum ChoiceKind { case chToTr, trToCh, listen }

struct Step: Identifiable {
    enum Kind {
        case learn(Phrase)
        case choice(Phrase, ChoiceKind)
        case build(Phrase)
        case match([Phrase])
    }
    let id = UUID()
    let kind: Kind
}

@MainActor
final class LessonModel: ObservableObject {
    let lesson: Lesson
    let mode: LessonMode
    @Published var steps: [Step]
    @Published var index = 0
    @Published var correct = 0
    @Published var answered = 0
    @Published var finished = false
    var mistakes: [String: Int] = [:]
    private var retried = Set<String>()

    init(lesson: Lesson, mode: LessonMode) {
        self.lesson = lesson
        self.mode = mode
        self.steps = Self.plan(lesson: lesson, mode: mode)
        #if DEBUG
        // Screenshot helper: `-kind choice|listen|build|match` starts on that exercise type.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-kind"), i + 1 < args.count {
            let want = args[i + 1]
            let pick = steps.first { step in
                switch step.kind {
                case .choice(_, let k): return (want == "listen" && k == .listen) || (want == "choice" && k == .trToCh)
                case .build: return want == "build"
                case .match: return want == "match"
                case .learn: return false
                }
            }
            if let pick { steps = [pick] + steps.filter { $0.id != pick.id } }
            self.index = 0
        }
        #endif
    }

    static func plan(lesson: Lesson, mode: LessonMode) -> [Step] {
        let ph = lesson.phrases
        var steps: [Step] = []
        if mode == .lesson { steps += ph.map { Step(kind: .learn($0)) } }
        var ex: [Step] = []
        for (i, p) in ph.shuffled().enumerated() {
            ex.append(Step(kind: .choice(p, i % 2 == 0 ? .chToTr : .trToCh)))
        }
        for p in ph.shuffled().prefix(3) { ex.append(Step(kind: .choice(p, .listen))) }
        for p in ph.filter({ $0.words.count >= 2 && $0.words.count <= 7 }).shuffled().prefix(3) {
            ex.append(Step(kind: .build(p)))
        }
        ex.shuffle()
        if ph.count >= 4 { ex.insert(Step(kind: .match(Array(ph.shuffled().prefix(5)))), at: min(3, ex.count)) }
        return steps + ex
    }

    var progress: Double { steps.isEmpty ? 1 : Double(index) / Double(steps.count) }
    var accuracy: Double { answered == 0 ? 1 : Double(correct) / Double(answered) }
    var xp: Int { correct * 2 + 10 + (mistakes.isEmpty ? 5 : 0) }

    func mistake(_ phraseID: String) { mistakes[phraseID, default: 0] += 1 }

    /// Called when an exercise is completed (after the user tapped "Continue").
    func done(step: Step, wasCorrect: Bool?, phrase: Phrase? = nil) {
        if let wasCorrect {
            answered += 1
            if wasCorrect { correct += 1 }
            else if let phrase {
                mistake(phrase.id)
                // give the learner a second chance at the end
                if !retried.contains(phrase.id) {
                    retried.insert(phrase.id)
                    steps.append(Step(kind: .choice(phrase, .trToCh)))
                }
            }
        }
        if index + 1 >= steps.count { finished = true } else { index += 1 }
    }
}

struct LessonView: View {
    let lesson: Lesson
    let mode: LessonMode
    @StateObject private var model: LessonModel
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var confirmExit = false
    @State private var saved = false

    init(lesson: Lesson, mode: LessonMode) {
        self.lesson = lesson
        self.mode = mode
        _model = StateObject(wrappedValue: LessonModel(lesson: lesson, mode: mode))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if model.finished {
                CompletionView(model: model, lesson: lesson, mode: mode, onClose: close, onUpsell: upsell)
                    .transition(.opacity)
                    .onAppear(perform: save)
            } else {
                VStack(spacing: 0) {
                    topBar
                    if model.index < model.steps.count {
                        let step = model.steps[model.index]
                        stepView(step)
                            .id(step.id)
                            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: model.index)
        .animation(.easeInOut(duration: 0.3), value: model.finished)
        .alert(tr("Lektion abbrechen?", "Quit lesson?"), isPresented: $confirmExit) {
            Button(tr("Weiter lernen", "Keep learning"), role: .cancel) {}
            Button(tr("Abbrechen", "Quit"), role: .destructive) { SpeechService.shared.stop(); dismiss() }
        } message: {
            Text(tr("Dein Fortschritt in dieser Lektion geht verloren.", "Your progress in this lesson will be lost."))
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { confirmExit = true } label: {
                Image(systemName: "xmark").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.muted)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(tr("Schliessen", "Close"))
            ProgressBar(value: model.progress, color: Theme.green)
            Text("\(min(model.index + 1, model.steps.count))/\(model.steps.count)")
                .font(.rounded(.caption, .bold)).foregroundStyle(Theme.muted).monospacedDigit()
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)
    }

    @ViewBuilder private func stepView(_ step: Step) -> some View {
        switch step.kind {
        case .learn(let p):
            LearnCard(phrase: p) { model.done(step: step, wasCorrect: nil) }
        case .choice(let p, let kind):
            ChoiceExercise(phrase: p, kind: kind) { ok in model.done(step: step, wasCorrect: ok, phrase: p) }
        case .build(let p):
            BuildExercise(phrase: p) { ok in model.done(step: step, wasCorrect: ok, phrase: p) }
        case .match(let ps):
            MatchExercise(phrases: ps, onMistake: { model.mistake($0) }) { ok in model.done(step: step, wasCorrect: ok) }
        }
    }

    private func save() {
        guard !saved else { return }
        saved = true
        switch mode {
        case .lesson: store.finish(lesson: lesson, xpGained: model.xp, mistakes: model.mistakes)
        case .practice: store.recordPractice(xp: model.xp, mistakes: model.mistakes)
        }
        if mode == .practice {
            store.clearWeak(lesson.phrases.map { $0.id }.filter { model.mistakes[$0] == nil })
        }
    }

    private func close() {
        SpeechService.shared.stop()
        dismiss()
    }

    private func upsell() {
        SpeechService.shared.stop()
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { router.showPaywall("post-free") }
    }
}

// MARK: - Shared bits

struct ProgressBar: View {
    var value: Double
    var color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.line)
                Capsule().fill(color)
                    .frame(width: max(14, geo.size.width * value))
                    .animation(.spring(response: 0.4), value: value)
            }
        }
        .frame(height: 14)
    }
}

struct SpeakButton: View {
    let text: String
    var size: CGFloat = 52
    var slow = false
    var body: some View {
        Button { SpeechService.shared.speak(text, slow: slow) } label: {
            Image(systemName: slow ? "tortoise.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(slow ? Theme.orange : Theme.blue, in: Circle())
        }
        .accessibilityLabel(slow ? tr("Langsam anhören", "Listen slowly") : tr("Anhören", "Listen"))
    }
}

struct FeedbackBar: View {
    let correct: Bool
    let answer: String
    var note: String? = nil
    var onContinue: () -> Void

    private static let praiseDE = ["Genau!", "Super!", "Stark!", "Mega!", "Perfekt!", "Lässig!"]
    private static let praiseEN = ["Exactly!", "Great!", "Nice!", "Awesome!", "Perfect!", "Brilliant!"]
    @State private var praise = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill").font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(correct
                         ? (AppLanguage.current == .de ? Self.praiseDE : Self.praiseEN)[praise % 6]
                         : tr("Nicht ganz – so ist es richtig:", "Not quite – the answer is:"))
                        .font(.rounded(.headline, .heavy))
                    if !correct { Text(answer).font(.rounded(.subheadline, .semibold)) }
                    if let note, correct { Text(note).font(.rounded(.footnote)).opacity(0.9) }
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(correct ? Theme.greenDeep : Theme.redDeep)
            Button(action: onContinue) { Text(tr("Weiter", "Continue")).textCase(.uppercase) }
                .buttonStyle(ChunkyButtonStyle(color: correct ? Theme.green : Theme.red, deep: correct ? Theme.greenDeep : Theme.redDeep))
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 8)
        .frame(maxWidth: .infinity)
        .background((correct ? Theme.green : Theme.red).opacity(0.14).background(Theme.bg))
        .onAppear {
            praise = Int.random(in: 0..<6)
            UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
        }
    }
}

// MARK: - Completion

struct CompletionView: View {
    @ObservedObject var model: LessonModel
    let lesson: Lesson
    let mode: LessonMode
    var onClose: () -> Void
    var onUpsell: () -> Void
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @Environment(\.requestReview) private var requestReview
    @State private var appear = false

    private var nextLocked: Bool {
        guard mode == .lesson, !purchases.isPremium, let next = store.nextLesson, let unit = Curriculum.unit(next.unitID) else { return false }
        return !unit.isFree
    }

    var body: some View {
        ZStack {
            ConfettiView()
            VStack(spacing: 22) {
                Spacer()
                Text(model.mistakes.isEmpty ? "🏆" : "🎉").font(.system(size: 88))
                    .scaleEffect(appear ? 1 : 0.3).animation(.spring(response: 0.5, dampingFraction: 0.55), value: appear)
                Text(mode == .lesson ? tr("Lektion geschafft!", "Lesson complete!") : tr("Übung geschafft!", "Practice complete!"))
                    .font(.rounded(.largeTitle, .heavy)).multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    stat(icon: "bolt.fill", color: Theme.gold, value: "+\(model.xp)", label: "XP")
                    stat(icon: "target", color: Theme.green, value: "\(Int((model.accuracy * 100).rounded()))%", label: tr("Treffer", "Accuracy"))
                    stat(icon: "flame.fill", color: Theme.orange, value: "\(store.streak)", label: tr("Serie", "Streak"))
                }
                if store.goalProgress >= 1 {
                    Label(tr("Tagesziel erreicht!", "Daily goal reached!"), systemImage: "checkmark.seal.fill")
                        .font(.rounded(.headline, .bold)).foregroundStyle(Theme.green)
                }
                if nextLocked, let next = store.nextLesson, let unit = Curriculum.unit(next.unitID) {
                    VStack(spacing: 6) {
                        Text("\(unit.emoji) " + unit.title).font(.rounded(.headline, .heavy))
                        Text(tr("Das nächste Kapitel ist Premium. Teste es 7 Tage gratis.", "The next chapter is Premium. Try it free for 7 days."))
                            .font(.rounded(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).card()
                }
                Spacer()
                if nextLocked {
                    Button(action: onUpsell) { Text(tr("Premium entdecken", "Discover Premium")).textCase(.uppercase) }
                        .buttonStyle(.chunky)
                    Button(tr("Nicht jetzt", "Not now"), action: onClose)
                        .font(.rounded(.subheadline, .bold)).foregroundStyle(Theme.muted)
                } else {
                    Button(action: onClose) { Text(tr("Weiter", "Continue")).textCase(.uppercase) }
                        .buttonStyle(.chunkyGreen)
                }
            }
            .padding(24)
        }
        .onAppear {
            appear = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            askForReviewIfAppropriate()
        }
    }

    private func stat(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(color)
            Text(value).font(.rounded(.title3, .heavy)).foregroundStyle(Theme.ink)
            Text(label).font(.rounded(.caption, .semibold)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity).card(padding: 14)
    }

    /// Ask for a rating right after a success moment (Apple limits how often this really shows).
    private func askForReviewIfAppropriate() {
        let n = store.state.lessonsFinished
        guard mode == .lesson, model.accuracy >= 0.8, [3, 8, 20].contains(n), store.state.reviewPromptedAtLesson != n else { return }
        store.state.reviewPromptedAtLesson = n
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { requestReview() }
    }
}

struct ConfettiView: View {
    private struct Piece: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let duration: Double
        let emoji: String
        let size: CGFloat
    }
    private let pieces: [Piece] = (0..<26).map { _ in
        Piece(x: .random(in: 0...1), delay: .random(in: 0...0.6), duration: .random(in: 2.2...3.6),
              emoji: ["🧀", "🇨🇭", "⭐️", "🏔️", "🎉", "🍫"].randomElement()!, size: .random(in: 18...30))
    }
    @State private var fall = false

    var body: some View {
        GeometryReader { geo in
            ForEach(pieces) { p in
                Text(p.emoji).font(.system(size: p.size))
                    .position(x: p.x * geo.size.width, y: fall ? geo.size.height + 60 : -40)
                    .rotationEffect(.degrees(fall ? 360 : 0))
                    .animation(.easeIn(duration: p.duration).delay(p.delay), value: fall)
            }
        }
        .allowsHitTesting(false)
        .onAppear { fall = true }
        .accessibilityHidden(true)
    }
}

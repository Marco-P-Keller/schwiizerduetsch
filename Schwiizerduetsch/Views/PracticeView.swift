import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @State private var session: Lesson?
    @State private var showQuiz = false

    private var reviewPool: [Phrase] {
        let weak = store.weakPhrases.shuffled()
        let rest = store.learnedPhrases.filter { p in !weak.contains(p) }.shuffled()
        return Array((weak + rest).prefix(8))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Smart review
                    Button(action: startReview) {
                        HStack(spacing: 14) {
                            Image(systemName: "bolt.heart.fill").font(.system(size: 26)).foregroundStyle(.white)
                                .frame(width: 56, height: 56).background(Theme.red, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text(tr("Smarte Wiederholung", "Smart review")).font(.rounded(.headline, .heavy))
                                    if !purchases.isPremium { premiumBadge }
                                }
                                Text(store.learnedPhrases.count < 4
                                     ? tr("Schliesse zuerst ein paar Lektionen ab.", "Complete a few lessons first.")
                                     : (store.weakPhrases.isEmpty
                                        ? tr("Frische deine gelernten Ausdrücke auf.", "Refresh the phrases you've learned.")
                                        : trf("%d Ausdrücke brauchen Übung.", "%d phrases need practice.", store.weakPhrases.count)))
                                    .font(.rounded(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(Theme.ink)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)

                    NavigationLink { QuizView() } label: {
                        HStack(spacing: 14) {
                            Text("🇨🇭").font(.system(size: 30)).frame(width: 56, height: 56)
                                .background(Theme.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(tr("Wie schweizerisch bist du?", "How Swiss are you?")).font(.rounded(.headline, .heavy))
                                Text(store.state.quizBest > 0
                                     ? trf("Deine Bestleistung: %d/10 – kannst du dich verbessern?", "Your best: %d/10 – can you beat it?", store.state.quizBest)
                                     : tr("10 Fragen. Teile dein Resultat mit Freunden!", "10 questions. Share your result with friends!"))
                                    .font(.rounded(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(Theme.ink)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)

                    NavigationLink { PhrasebookView() } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "text.book.closed.fill").font(.system(size: 24)).foregroundStyle(Theme.blue)
                                .frame(width: 56, height: 56).background(Theme.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Phrasebook").font(.rounded(.headline, .heavy))
                                Text(trf("%d Ausdrücke zum Nachschlagen und Anhören", "%d phrases to look up and listen to", Curriculum.allPhrases.count))
                                    .font(.rounded(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(Theme.ink)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").foregroundStyle(Theme.muted)
                        }
                        .card()
                    }
                    .buttonStyle(.plain)

                    PhraseOfTheDayCard()

                    if !store.state.favorites.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(tr("Deine Favoriten", "Your favourites")).font(.rounded(.headline, .heavy)).foregroundStyle(Theme.ink)
                            ForEach(store.state.favorites.compactMap { Curriculum.phrase($0) }) { p in
                                PhraseRow(phrase: p, locked: false)
                                if p.id != store.state.favorites.last { Divider() }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).card()
                    }
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(tr("Üben", "Practice"))
        }
        .fullScreenCover(item: $session) { s in LessonView(lesson: s, mode: .practice) }
    }

    private var premiumBadge: some View {
        Text("PREMIUM").font(.rounded(size: 10, .heavy)).foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 2).background(Theme.gold, in: Capsule())
    }

    private func startReview() {
        guard purchases.isPremium else { router.showPaywall("review"); return }
        guard store.learnedPhrases.count >= 4 else { return }
        session = Lesson(id: "practice-\(UUID().uuidString)", unitID: "practice", index: 0, phrases: reviewPool)
    }
}

// MARK: - Phrasebook

struct PhraseRow: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var router: AppRouter
    let phrase: Phrase
    let locked: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(phrase.ch).font(.rounded(.body, .bold)).foregroundStyle(Theme.ink)
                Text(phrase.translation).font(.rounded(.footnote)).foregroundStyle(Theme.muted)
            }
            .redacted(reason: locked ? .placeholder : [])
            Spacer(minLength: 8)
            if locked {
                Image(systemName: "lock.fill").foregroundStyle(Theme.muted)
            } else {
                Button { store.toggleFavorite(phrase) } label: {
                    Image(systemName: store.isFavorite(phrase) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(phrase) ? Theme.red : Theme.muted)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tr("Favorit", "Favourite"))
                Button { SpeechService.shared.speak(phrase.ch) } label: {
                    Image(systemName: "speaker.wave.2.fill").foregroundStyle(Theme.blue)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tr("Anhören", "Listen"))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { if locked { router.showPaywall("phrasebook") } }
    }
}

struct PhrasebookView: View {
    @EnvironmentObject var purchases: PurchaseManager
    @State private var query = ""

    private func matches(_ p: Phrase) -> Bool {
        query.isEmpty || p.ch.localizedCaseInsensitiveContains(query)
            || p.de.localizedCaseInsensitiveContains(query) || p.en.localizedCaseInsensitiveContains(query)
    }

    var body: some View {
        List {
            ForEach(Curriculum.units) { unit in
                let items = unit.phrases.filter(matches)
                if !items.isEmpty {
                    Section {
                        ForEach(Array(items.enumerated()), id: \.element.id) { i, p in
                            PhraseRow(phrase: p, locked: !unit.isFree && !purchases.isPremium && (unit.phrases.firstIndex(of: p) ?? 0) >= 3)
                        }
                    } header: {
                        Text("\(unit.emoji) \(unit.title)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
        .searchable(text: $query, prompt: tr("Suche", "Search"))
        .navigationTitle("Phrasebook")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Quiz

struct QuizView: View {
    @EnvironmentObject var store: ProgressStore
    @State private var index = 0
    @State private var score = 0
    @State private var selected: Int?
    @State private var done = false
    @State private var shareImage: Image?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if done { result } else { question }
        }
        .navigationTitle(tr("Swissness-Quiz", "Swissness quiz"))
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut, value: done)
    }

    private var question: some View {
        let q = Quiz.questions[index]
        return VStack(spacing: 0) {
            ProgressBar(value: Double(index) / Double(Quiz.questions.count), color: Theme.red).padding(20)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(trf("Frage %d von %d", "Question %d of %d", index + 1, Quiz.questions.count))
                        .font(.rounded(.caption, .bold)).foregroundStyle(Theme.muted).textCase(.uppercase)
                    Text(q.question).font(.rounded(.title2, .heavy)).foregroundStyle(Theme.ink)
                    ForEach(Array(q.options.enumerated()), id: \.offset) { i, opt in
                        let revealed = selected != nil
                        let isCorrect = i == q.answer
                        let isSel = selected == i
                        Button {
                            guard selected == nil else { return }
                            selected = i
                            if isCorrect { score += 1 }
                            UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)
                        } label: {
                            HStack {
                                Text(opt).font(.rounded(.body, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                                Spacer()
                                if revealed && (isCorrect || isSel) {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(isCorrect ? Theme.green : Theme.red)
                                }
                            }
                            .padding(16)
                            .background(revealed ? (isCorrect ? Theme.green.opacity(0.14) : (isSel ? Theme.red.opacity(0.12) : Theme.card)) : Theme.card,
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(revealed ? (isCorrect ? Theme.green : (isSel ? Theme.red : Theme.line)) : Theme.line, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                    if selected != nil {
                        Text(q.explain).font(.rounded(.subheadline)).foregroundStyle(Theme.ink)
                            .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.gold.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
            }
            if selected != nil {
                Button {
                    if index + 1 >= Quiz.questions.count { finish() } else { index += 1; selected = nil }
                } label: { Text(tr("Weiter", "Continue")).textCase(.uppercase) }
                    .buttonStyle(.chunky).padding(.horizontal, 20).padding(.bottom, 8)
            }
        }
    }

    private func finish() {
        store.state.quizBest = max(store.state.quizBest, score)
        store.recordPractice(xp: 10, mistakes: [:])
        let card = ShareCard(score: score, total: Quiz.questions.count)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let ui = renderer.uiImage { shareImage = Image(uiImage: ui) }
        done = true
    }

    private var result: some View {
        let rank = Quiz.rank(score: score)
        return ScrollView {
            VStack(spacing: 20) {
                ShareCard(score: score, total: Quiz.questions.count)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
                    .padding(.top, 20)
                if let shareImage {
                    ShareLink(item: shareImage,
                              subject: Text("Schwiizerdüütsch"),
                              message: Text(trf("Ich bin «%@» – wie Schweizerisch bist du? 🇨🇭 %@", "I'm a «%@» – how Swiss are you? 🇨🇭 %@", rank.title, AppLinks.appStore.absoluteString)),
                              preview: SharePreview(rank.title, image: shareImage)) {
                        Label(tr("Resultat teilen", "Share result"), systemImage: "square.and.arrow.up")
                            .textCase(.uppercase)
                    }
                    .buttonStyle(.chunky)
                }
                Button(tr("Nochmals versuchen", "Try again")) {
                    index = 0; score = 0; selected = nil; done = false
                }
                .font(.rounded(.headline, .bold)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }
}

struct ShareCard: View {
    let score: Int
    let total: Int

    var body: some View {
        let rank = Quiz.rank(score: score)
        VStack(spacing: 14) {
            Text("SCHWIIZERDÜÜTSCH").font(.rounded(size: 13, .heavy)).tracking(2).foregroundStyle(.white.opacity(0.85))
            Text(rank.emoji).font(.system(size: 84))
            Text(tr("Ich bin", "I'm a")).font(.rounded(size: 18, .semibold)).foregroundStyle(.white.opacity(0.9))
            Text(rank.title).font(.rounded(size: 32, .heavy)).foregroundStyle(.white).multilineTextAlignment(.center)
            Text("\(score)/\(total)").font(.rounded(size: 22, .heavy)).foregroundStyle(Theme.red)
                .padding(.horizontal, 18).padding(.vertical, 6).background(.white, in: Capsule())
            Text(tr("Wie schweizerisch bist du?", "How Swiss are you?")).font(.rounded(size: 16, .bold)).foregroundStyle(.white)
        }
        .padding(28)
        .frame(width: 340, height: 420)
        .background(LinearGradient(colors: [Color(hex: 0xFF3B47), Color(hex: 0xB3121F)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}

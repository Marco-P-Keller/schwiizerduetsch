import SwiftUI

/// Shared layout for the main tabs: alpine header illustration with a sheet of content on top.
struct ScreenScaffold<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var content: Content

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            MountainScene().frame(height: 330).ignoresSafeArea(edges: .top)
            ScrollView {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Spacer(minLength: 0)
                        Text(title).font(.display(36, .heavy)).foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 3)
                        if let subtitle {
                            Text(subtitle).font(.ui(.subheadline, .semibold)).foregroundStyle(.white.opacity(0.92))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22).padding(.bottom, 34)
                    .frame(height: 190)

                    VStack(spacing: 16) { content }
                        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
                        .frame(maxWidth: .infinity)
                        .background(
                            Theme.bg.clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 24, y: -6)
                        )
                }
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

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
            ScreenScaffold(title: tr("Üben", "Practice"), subtitle: tr("Festige, was du gelernt hast.", "Lock in what you've learned.")) {
                actionCard(icon: "bolt.heart.fill", tint: Theme.red, title: tr("Smarte Wiederholung", "Smart review"),
                           subtitle: store.learnedPhrases.count < 4
                               ? tr("Schliesse zuerst ein paar Lektionen ab.", "Complete a few lessons first.")
                               : (store.weakPhrases.isEmpty
                                  ? tr("Frische deine gelernten Ausdrücke auf.", "Refresh the phrases you've learned.")
                                  : trf("%d Ausdrücke brauchen Übung.", "%d phrases need practice.", store.weakPhrases.count)),
                           premium: !purchases.isPremium, action: startReview)

                NavigationLink { QuizView() } label: {
                    actionLabel(icon: "flag.fill", tint: Color(hex: 0xE3202D), title: tr("Wie schweizerisch bist du?", "How Swiss are you?"),
                                subtitle: store.state.quizBest > 0
                                    ? trf("Deine Bestleistung: %d/10 – kannst du dich verbessern?", "Your best: %d/10 – can you beat it?", store.state.quizBest)
                                    : tr("10 Fragen. Teile dein Resultat mit Freunden!", "10 questions. Share your result with friends!"), premium: false)
                }
                .buttonStyle(OptionPressStyle())

                NavigationLink { PhrasebookView() } label: {
                    actionLabel(icon: "text.book.closed.fill", tint: Theme.blue, title: "Phrasebook",
                                subtitle: trf("%d Ausdrücke zum Nachschlagen", "%d phrases to look up", Curriculum.allPhrases.count), premium: false)
                }
                .buttonStyle(OptionPressStyle())

                if !store.state.favorites.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tr("Deine Favoriten", "Your favourites")).font(.display(20, .heavy)).foregroundStyle(Theme.ink)
                        ForEach(store.state.favorites.compactMap { Curriculum.phrase($0) }) { p in
                            PhraseRow(phrase: p, locked: false)
                            if p.id != store.state.favorites.last { Divider() }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).card(padding: 20)
                }
            }
            .navigationDestination(isPresented: $showQuiz) { QuizView() }
            .onAppear {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-quiz") { showQuiz = true }
                #endif
            }
        }
        .fullScreenCover(item: $session) { s in LessonView(lesson: s, mode: .practice) }
    }

    private func actionCard(icon: String, tint: Color, title: String, subtitle: String, premium: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { actionLabel(icon: icon, tint: tint, title: title, subtitle: subtitle, premium: premium) }
            .buttonStyle(OptionPressStyle())
    }

    private func actionLabel(icon: String, tint: Color, title: String, subtitle: String, premium: Bool) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(LinearGradient(colors: [tint, tint.shaded(0.25)], startPoint: .top, endPoint: .bottom),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: tint.opacity(0.35), radius: 10, y: 5)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title).font(.ui(.headline, .heavy)).foregroundStyle(Theme.ink)
                    if premium {
                        Text("PREMIUM").font(.ui(size: 9, .heavy)).tracking(0.8).foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3).background(Theme.gold, in: Capsule())
                    }
                }
                Text(subtitle).font(.ui(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted.opacity(0.6))
        }
        .card(padding: 16)
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
                Text(phrase.ch).font(.display(18, .semibold)).foregroundStyle(Theme.ink)
                Text(phrase.translation).font(.ui(.footnote)).foregroundStyle(Theme.muted)
            }
            .redacted(reason: locked ? .placeholder : [])
            Spacer(minLength: 8)
            if locked {
                Image(systemName: "lock.fill").foregroundStyle(Theme.muted)
            } else {
                if SpeechService.shared.hasRecording(for: phrase.ch) {
                    Button { SpeechService.shared.speak(phrase.ch) } label: {
                        Image(systemName: "speaker.wave.2.fill").foregroundStyle(Theme.blue)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tr("Anhören", "Listen"))
                }
                Button { store.toggleFavorite(phrase) } label: {
                    Image(systemName: store.isFavorite(phrase) ? "heart.fill" : "heart")
                        .foregroundStyle(store.isFavorite(phrase) ? Theme.red : Theme.muted)
                        .symbolEffect(.bounce, value: store.isFavorite(phrase))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tr("Favorit", "Favourite"))
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
                        ForEach(items) { p in
                            PhraseRow(phrase: p, locked: !unit.isFree && !purchases.isPremium && (unit.phrases.firstIndex(of: p) ?? 0) >= 3)
                                .listRowBackground(Theme.card)
                        }
                    } header: {
                        Text("\(unit.emoji)  \(unit.title)").font(.ui(.subheadline, .bold)).foregroundStyle(Theme.ink).textCase(nil)
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
        .toolbar(.visible, for: .navigationBar)
        .animation(.easeInOut, value: done)
        .onAppear {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-quizdone"), !done { score = 8; finish() }
            #endif
        }
    }

    private var question: some View {
        let q = Quiz.questions[index]
        return VStack(spacing: 0) {
            ProgressBar(value: Double(index) / Double(Quiz.questions.count), color: Theme.red, height: 10).padding(20)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text(trf("Frage %d von %d", "Question %d of %d", index + 1, Quiz.questions.count)).eyebrow()
                    Text(q.question).font(.display(28, .heavy)).foregroundStyle(Theme.ink)
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
                                Text(opt).font(.ui(.body, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                                Spacer()
                                if revealed && (isCorrect || isSel) {
                                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title3).foregroundStyle(isCorrect ? Theme.green : Theme.red)
                                }
                            }
                            .padding(18)
                            .background(revealed ? (isCorrect ? Theme.green.opacity(0.12) : (isSel ? Theme.red.opacity(0.10) : Theme.card)) : Theme.card,
                                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(revealed ? (isCorrect ? Theme.green : (isSel ? Theme.red : Theme.line)) : Theme.line, lineWidth: revealed && (isCorrect || isSel) ? 2 : 1.2))
                            .shadow(color: .black.opacity(revealed ? 0 : 0.05), radius: 10, y: 5)
                        }
                        .buttonStyle(OptionPressStyle())
                    }
                    if selected != nil {
                        Text(q.explain).font(.ui(.subheadline)).foregroundStyle(Theme.ink)
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
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
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selected)
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
            VStack(spacing: 22) {
                ShareCard(score: score, total: Quiz.questions.count)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .shadow(color: .black.opacity(0.2), radius: 26, y: 14)
                    .padding(.top, 20)
                if let shareImage {
                    ShareLink(item: shareImage,
                              subject: Text("Schwiizerdüütsch"),
                              message: Text(trf("Ich bin «%@» – wie schweizerisch bist du? 🇨🇭 %@", "I'm a «%@» – how Swiss are you? 🇨🇭 %@", rank.title, AppLinks.appStore.absoluteString)),
                              preview: SharePreview(rank.title, image: shareImage)) {
                        Label(tr("Resultat teilen", "Share result"), systemImage: "square.and.arrow.up").textCase(.uppercase)
                    }
                    .buttonStyle(.chunky)
                }
                Button(tr("Nochmals versuchen", "Try again")) {
                    index = 0; score = 0; selected = nil; done = false
                }
                .font(.ui(.headline, .bold)).foregroundStyle(Theme.muted)
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
        ZStack(alignment: .top) {
            Color(hex: 0x3D3876)
            MountainScene(fadeTo: Color(hex: 0x3D3876)).frame(height: 300)
            VStack(spacing: 10) {
                Text("SCHWIIZERDÜÜTSCH").font(.ui(size: 12, .heavy)).tracking(2.4).foregroundStyle(.white.opacity(0.9)).padding(.top, 24)
                Spacer().frame(height: 34)
                Text(rank.emoji).font(.system(size: 76)).shadow(color: .black.opacity(0.25), radius: 10, y: 6)
                Text(tr("Ich bin", "I'm a")).font(.ui(size: 16, .semibold)).foregroundStyle(.white.opacity(0.85))
                Text(rank.title).font(.display(32, .heavy)).foregroundStyle(.white).multilineTextAlignment(.center)
                Text("\(score)/\(total)").font(.numeric(22)).foregroundStyle(Theme.red)
                    .padding(.horizontal, 20).padding(.vertical, 7).background(.white, in: Capsule())
                Spacer()
                Text(tr("Wie schweizerisch bist du?", "How Swiss are you?")).font(.ui(size: 16, .bold)).foregroundStyle(.white).padding(.bottom, 26)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: 340, height: 460)
    }
}

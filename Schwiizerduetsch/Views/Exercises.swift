import SwiftUI

// MARK: - Learn card

struct LearnCard: View {
    let phrase: Phrase
    var tint: Color = Theme.red
    var onContinue: () -> Void
    @EnvironmentObject var store: ProgressStore
    @State private var appear = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
            ScrollView {
                VStack(spacing: 20) {
                    Text(tr("Neu", "New")).eyebrow(tint)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(tint.opacity(0.12), in: Capsule())
                    VStack(spacing: 18) {
                        Image(systemName: "quote.opening").font(.system(size: 26, weight: .bold)).foregroundStyle(tint.opacity(0.4)).frame(height: 30)
                        Text(phrase.ch)
                            .font(.display(38, .bold)).foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6).fixedSize(horizontal: false, vertical: true)
                        if SpeechService.shared.hasRecording(for: phrase.ch) {
                            HStack(spacing: 14) {
                                SpeakButton(text: phrase.ch)
                                SpeakButton(text: phrase.ch, size: 44, slow: true)
                            }
                        }
                        Capsule().fill(Theme.line).frame(width: 44, height: 3)
                        Text(phrase.translation)
                            .font(.ui(.title3, .medium)).foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 30).padding(.horizontal, 22)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Theme.card)
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(LinearGradient(colors: [tint.opacity(0.10), .clear], startPoint: .top, endPoint: .center))
                        }
                    )
                    .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).strokeBorder(Theme.line.opacity(0.8), lineWidth: 1))
                    .shadow(color: tint.opacity(0.14), radius: 26, y: 14)
                    .scaleEffect(appear ? 1 : 0.94).opacity(appear ? 1 : 0)
                    if let note = phrase.note {
                        HStack(alignment: .top, spacing: 12) {
                            Text("💡").font(.title3)
                            Text(note).font(.ui(.subheadline)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gold.opacity(0.15), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.gold.opacity(0.25), lineWidth: 1))
                        .opacity(appear ? 1 : 0).offset(y: appear ? 0 : 12)
                    }
                }
                .padding(.horizontal, 20)
                .frame(minHeight: geo.size.height, alignment: .center)
            }
            }
            Button(action: onContinue) { Text(tr("Weiter", "Continue")).textCase(.uppercase) }
                .buttonStyle(.chunky)
                .padding(.horizontal, 20).padding(.bottom, 8).padding(.top, 6)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) { appear = true }
            if store.state.autoplay, SpeechService.shared.hasRecording(for: phrase.ch) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { SpeechService.shared.speak(phrase.ch) }
            }
        }
    }
}

// MARK: - Multiple choice

struct ChoiceExercise: View {
    let phrase: Phrase
    let kind: ChoiceKind
    var onDone: (Bool) -> Void
    @State private var options: [String]
    @State private var selected: String?

    init(phrase: Phrase, kind: ChoiceKind, onDone: @escaping (Bool) -> Void) {
        self.phrase = phrase
        self.kind = kind
        self.onDone = onDone
        let correct = kind == .chToTr ? phrase.translation : phrase.ch
        let texts: (Phrase) -> String = { kind == .chToTr ? $0.translation : $0.ch }
        var opts = [correct]
        for p in Self.distractors(for: phrase, count: 3) {
            let t = texts(p)
            if !opts.contains(t) { opts.append(t) }
            if opts.count == 4 { break }
        }
        _options = State(initialValue: opts.shuffled())
    }

    static func distractors(for phrase: Phrase, count: Int) -> [Phrase] {
        let unitID = phrase.id.split(separator: "-").first.map(String.init) ?? ""
        let same = (Curriculum.unit(unitID)?.phrases ?? []).filter { $0.id != phrase.id }.shuffled()
        let others = Curriculum.allPhrases.filter { $0.id != phrase.id && !same.contains($0) }.shuffled()
        return Array((same + others).prefix(count * 3))
    }

    private var correctText: String { kind == .chToTr ? phrase.translation : phrase.ch }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(prompt).eyebrow()
                    switch kind {
                    case .chToTr:
                        HStack(spacing: 14) {
                            SpeakButton(text: phrase.ch, size: 46)
                            Text(phrase.ch).font(.display(30, .bold)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
                        }
                    case .trToCh:
                        Text(phrase.translation).font(.ui(.title2, .bold)).foregroundStyle(Theme.ink)
                            .padding(20).frame(maxWidth: .infinity, alignment: .leading).card(padding: 0)
                    case .listen:
                        HStack(spacing: 16) {
                            SpeakButton(text: phrase.ch, size: 76)
                            SpeakButton(text: phrase.ch, size: 52, slow: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 12) {
                        ForEach(options, id: \.self) { opt in optionButton(opt) }
                    }
                }
                .padding(20)
            }
            if let selected {
                FeedbackBar(correct: selected == correctText, answer: correctText, note: phrase.note) {
                    onDone(selected == correctText)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: selected)
        .onAppear {
            if kind == .listen { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { SpeechService.shared.speak(phrase.ch) } }
        }
    }

    private var prompt: String {
        switch kind {
        case .chToTr: return tr("Was bedeutet das?", "What does this mean?")
        case .trToCh: return tr("Wie sagt man das auf Schwiizerdüütsch?", "How do you say this in Swiss German?")
        case .listen: return tr("Was hörst du?", "What do you hear?")
        }
    }

    private func optionButton(_ opt: String) -> some View {
        let isSelected = selected == opt
        let isCorrect = opt == correctText
        let revealed = selected != nil
        let tone: Color = revealed ? (isCorrect ? Theme.green : (isSelected ? Theme.red : Theme.line)) : Theme.line
        let bg: Color = revealed ? (isCorrect ? Theme.green.opacity(0.12) : (isSelected ? Theme.red.opacity(0.10) : Theme.card)) : Theme.card
        return Button {
            guard selected == nil else { return }
            selected = opt
        } label: {
            HStack(spacing: 12) {
                Text(opt).font(kind == .chToTr ? .ui(.body, .semibold) : .display(19, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if revealed && (isCorrect || isSelected) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3).foregroundStyle(isCorrect ? Theme.green : Theme.red).transition(.scale)
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 17)
            .background(bg, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(tone, lineWidth: revealed && (isCorrect || isSelected) ? 2 : 1.2))
            .shadow(color: .black.opacity(revealed ? 0 : 0.05), radius: 10, y: 5)
        }
        .buttonStyle(OptionPressStyle())
        .disabled(revealed)
    }
}

struct OptionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Build a sentence

struct BuildExercise: View {
    struct Token: Identifiable, Equatable { let id = UUID(); let text: String }

    let phrase: Phrase
    var onDone: (Bool) -> Void
    @State private var bank: [Token]
    @State private var answer: [Token] = []
    @State private var result: Bool?

    init(phrase: Phrase, onDone: @escaping (Bool) -> Void) {
        self.phrase = phrase
        self.onDone = onDone
        var tokens = phrase.words.map { Token(text: $0) }
        var shuffled = tokens.shuffled()
        var tries = 0
        while shuffled.map(\.text) == tokens.map(\.text) && tries < 5 { shuffled = tokens.shuffled(); tries += 1 }
        tokens = shuffled
        _bank = State(initialValue: tokens)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(tr("Übersetze ins Schwiizerdüütsch", "Translate into Swiss German")).eyebrow()
                    Text(phrase.translation).font(.ui(.title2, .bold)).foregroundStyle(Theme.ink)
                        .padding(20).frame(maxWidth: .infinity, alignment: .leading).card(padding: 0)

                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ForEach(0..<2, id: \.self) { _ in
                                Spacer().frame(height: 54)
                                Rectangle().fill(Theme.line).frame(height: 2)
                            }
                        }
                        FlowLayout(spacing: 8) {
                            ForEach(answer) { t in
                                chip(t).onTapGesture { if result == nil { move(t, toAnswer: false) } }
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(minHeight: 112, alignment: .topLeading)

                    FlowLayout(spacing: 8) {
                        ForEach(bank) { t in
                            chip(t).onTapGesture { if result == nil { move(t, toAnswer: true) } }
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(20)
            }
            if let result {
                FeedbackBar(correct: result, answer: phrase.ch, note: phrase.note) { onDone(result) }
                    .transition(.move(edge: .bottom))
            } else {
                Button { result = answer.map(\.text) == phrase.words } label: {
                    Text(tr("Prüfen", "Check")).textCase(.uppercase)
                }
                .buttonStyle(.chunky(disabled: answer.isEmpty))
                .disabled(answer.isEmpty)
                .padding(.horizontal, 20).padding(.bottom, 8)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: result)
    }

    private func chip(_ t: Token) -> some View {
        Text(t.text)
            .font(.display(19, .semibold)).foregroundStyle(Theme.ink)
            .padding(.horizontal, 15).padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.10), radius: 0, y: 3)
            )
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.line, lineWidth: 1.2))
            .accessibilityAddTraits(.isButton)
    }

    private func move(_ t: Token, toAnswer: Bool) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
            if toAnswer, let i = bank.firstIndex(of: t) { bank.remove(at: i); answer.append(t) }
            else if let i = answer.firstIndex(of: t) { answer.remove(at: i); bank.append(t) }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Match pairs

struct MatchExercise: View {
    let phrases: [Phrase]
    var onMistake: (String) -> Void
    var onDone: (Bool) -> Void
    @State private var left: [Phrase]
    @State private var right: [Phrase]
    @State private var selLeft: String?
    @State private var selRight: String?
    @State private var matched: Set<String> = []
    @State private var wrong: (String, String)?
    @State private var mistakes = 0
    @State private var finished = false

    init(phrases: [Phrase], onMistake: @escaping (String) -> Void, onDone: @escaping (Bool) -> Void) {
        self.phrases = phrases
        self.onMistake = onMistake
        self.onDone = onDone
        _left = State(initialValue: phrases.shuffled())
        _right = State(initialValue: phrases.shuffled())
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(tr("Finde die Paare", "Match the pairs")).eyebrow()
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 12) { ForEach(left) { p in tile(p, text: p.ch, isLeft: true) } }
                        VStack(spacing: 12) { ForEach(right) { p in tile(p, text: p.translation, isLeft: false) } }
                    }
                }
                .padding(20)
            }
            if finished {
                FeedbackBar(correct: mistakes == 0, answer: tr("Nimm dir Zeit – du schaffst das!", "Take your time – you've got this!")) { onDone(mistakes == 0) }
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.85), value: finished)
    }

    private func tile(_ p: Phrase, text: String, isLeft: Bool) -> some View {
        let isMatched = matched.contains(p.id)
        let isSel = isLeft ? selLeft == p.id : selRight == p.id
        let isWrong = wrong.map { isLeft ? $0.0 == p.id : $0.1 == p.id } ?? false
        let tone: Color = isMatched ? Theme.green : (isWrong ? Theme.red : (isSel ? Theme.blue : Theme.line))
        let bg: Color = isMatched ? Theme.green.opacity(0.12) : (isWrong ? Theme.red.opacity(0.10) : (isSel ? Theme.blue.opacity(0.10) : Theme.card))
        return Button { tap(p, isLeft: isLeft) } label: {
            Text(text).font(isLeft ? .display(17, .semibold) : .ui(.subheadline, .semibold)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center).minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 68).padding(.horizontal, 10)
                .background(bg, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(tone, lineWidth: isSel || isMatched || isWrong ? 2 : 1.2))
                .shadow(color: .black.opacity(isMatched ? 0 : 0.05), radius: 8, y: 4)
                .opacity(isMatched ? 0.5 : 1)
                .scaleEffect(isWrong ? 0.96 : 1)
        }
        .buttonStyle(OptionPressStyle())
        .disabled(isMatched || finished)
    }

    private func tap(_ p: Phrase, isLeft: Bool) {
        if isLeft {
            selLeft = p.id
            SpeechService.shared.speak(p.ch)
        } else { selRight = p.id }
        UISelectionFeedbackGenerator().selectionChanged()
        guard let l = selLeft, let r = selRight else { return }
        if l == r {
            withAnimation(.spring) { matched.insert(l) }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selLeft = nil; selRight = nil
            if matched.count == phrases.count { finished = true }
        } else {
            mistakes += 1
            onMistake(l)
            withAnimation(.spring(response: 0.25)) { wrong = (l, r) }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { wrong = nil }
                selLeft = nil; selRight = nil
            }
        }
    }
}

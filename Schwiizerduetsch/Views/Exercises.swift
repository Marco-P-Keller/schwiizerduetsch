import SwiftUI

// MARK: - Learn card

struct LearnCard: View {
    let phrase: Phrase
    var onContinue: () -> Void
    @EnvironmentObject var store: ProgressStore

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 22) {
                    Text(tr("Neu", "New")).font(.rounded(.caption, .heavy)).textCase(.uppercase)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Theme.blue.opacity(0.14), in: Capsule()).foregroundStyle(Theme.blue)
                        .padding(.top, 24)
                    VStack(spacing: 16) {
                        Text(phrase.ch)
                            .font(.rounded(size: 36, .heavy)).foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center).minimumScaleFactor(0.6)
                        HStack(spacing: 14) {
                            SpeakButton(text: phrase.ch)
                            SpeakButton(text: phrase.ch, size: 44, slow: true)
                        }
                        Divider()
                        Text(phrase.translation)
                            .font(.rounded(.title3, .semibold)).foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).card(padding: 24)
                    if let note = phrase.note {
                        HStack(alignment: .top, spacing: 10) {
                            Text("💡").font(.title3)
                            Text(note).font(.rounded(.subheadline)).foregroundStyle(Theme.ink)
                        }
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gold.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
            }
            Button(action: onContinue) { Text(tr("Weiter", "Continue")).textCase(.uppercase) }
                .buttonStyle(.chunky)
                .padding(.horizontal, 20).padding(.bottom, 8)
        }
        .onAppear {
            if store.state.autoplay {
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
    @EnvironmentObject var store: ProgressStore
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
                    Text(prompt).font(.rounded(.title3, .heavy)).foregroundStyle(Theme.ink)
                    switch kind {
                    case .chToTr:
                        HStack(spacing: 14) {
                            SpeakButton(text: phrase.ch, size: 46)
                            Text(phrase.ch).font(.rounded(.title2, .bold)).foregroundStyle(Theme.ink)
                        }
                    case .trToCh:
                        Text(phrase.translation).font(.rounded(.title2, .bold)).foregroundStyle(Theme.ink)
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading).card(padding: 0)
                    case .listen:
                        HStack(spacing: 16) {
                            SpeakButton(text: phrase.ch, size: 76)
                            SpeakButton(text: phrase.ch, size: 52, slow: true)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 10) {
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
        .animation(.spring(response: 0.35), value: selected)
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
        let border: Color = revealed ? (isCorrect ? Theme.green : (isSelected ? Theme.red : Theme.line)) : Theme.line
        let bg: Color = revealed ? (isCorrect ? Theme.green.opacity(0.14) : (isSelected ? Theme.red.opacity(0.12) : Theme.card)) : Theme.card
        return Button {
            guard selected == nil else { return }
            selected = opt
        } label: {
            HStack {
                Text(opt).font(.rounded(.body, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                Spacer(minLength: 8)
                if revealed && (isCorrect || isSelected) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? Theme.green : Theme.red)
                }
            }
            .padding(16)
            .background(bg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
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
                    Text(tr("Übersetze ins Schwiizerdüütsch", "Translate into Swiss German"))
                        .font(.rounded(.title3, .heavy)).foregroundStyle(Theme.ink)
                    Text(phrase.translation).font(.rounded(.title2, .bold)).foregroundStyle(Theme.ink)
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading).card(padding: 0)

                    // answer area
                    ZStack(alignment: .topLeading) {
                        VStack(spacing: 0) {
                            ForEach(0..<2, id: \.self) { _ in
                                Spacer().frame(height: 52)
                                Rectangle().fill(Theme.line).frame(height: 2)
                            }
                        }
                        FlowLayout(spacing: 8) {
                            ForEach(answer) { t in
                                chip(t).onTapGesture { if result == nil { move(t, toAnswer: false) } }
                            }
                        }
                    }
                    .frame(minHeight: 108, alignment: .topLeading)

                    FlowLayout(spacing: 8) {
                        ForEach(bank) { t in
                            chip(t).onTapGesture { if result == nil { move(t, toAnswer: true) } }
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
        .animation(.spring(response: 0.35), value: result)
    }

    private func chip(_ t: Token) -> some View {
        Text(t.text)
            .font(.rounded(.body, .semibold)).foregroundStyle(Theme.ink)
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.line, lineWidth: 2))
            .shadow(color: Theme.line, radius: 0, y: 3)
            .accessibilityAddTraits(.isButton)
    }

    private func move(_ t: Token, toAnswer: Bool) {
        withAnimation(.spring(response: 0.3)) {
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
                    Text(tr("Finde die Paare", "Match the pairs")).font(.rounded(.title3, .heavy)).foregroundStyle(Theme.ink)
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 10) { ForEach(left) { p in tile(p, text: p.ch, isLeft: true) } }
                        VStack(spacing: 10) { ForEach(right) { p in tile(p, text: p.translation, isLeft: false) } }
                    }
                }
                .padding(20)
            }
            if finished {
                FeedbackBar(correct: mistakes == 0, answer: tr("Nimm dir Zeit – du schaffst das!", "Take your time – you've got this!")) { onDone(mistakes == 0) }
                    .transition(.move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.35), value: finished)
    }

    private func tile(_ p: Phrase, text: String, isLeft: Bool) -> some View {
        let isMatched = matched.contains(p.id)
        let isSel = isLeft ? selLeft == p.id : selRight == p.id
        let isWrong = wrong.map { isLeft ? $0.0 == p.id : $0.1 == p.id } ?? false
        let border: Color = isMatched ? Theme.green : (isWrong ? Theme.red : (isSel ? Theme.blue : Theme.line))
        let bg: Color = isMatched ? Theme.green.opacity(0.14) : (isWrong ? Theme.red.opacity(0.12) : (isSel ? Theme.blue.opacity(0.12) : Theme.card))
        return Button { tap(p, isLeft: isLeft) } label: {
            Text(text).font(.rounded(.subheadline, .semibold)).foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center).minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity, minHeight: 64).padding(.horizontal, 8)
                .background(bg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(border, lineWidth: 2))
                .opacity(isMatched ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isMatched || finished)
    }

    private func tap(_ p: Phrase, isLeft: Bool) {
        if isLeft {
            selLeft = p.id
            if isLeft, !p.ch.isEmpty { SpeechService.shared.speak(p.ch) }
        } else { selRight = p.id }
        guard let l = selLeft, let r = selRight else { return }
        if l == r {
            matched.insert(l)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            selLeft = nil; selRight = nil
            if matched.count == phrases.count { finished = true }
        } else {
            mistakes += 1
            onMistake(l)
            wrong = (l, r)
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wrong = nil; selLeft = nil; selRight = nil
            }
        }
    }
}

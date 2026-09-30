import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @State private var activeLesson: Lesson?
    @State private var showStreak = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    StatsBar(showStreak: $showStreak)
                    ContinueCard(start: start)
                    PhraseOfTheDayCard()
                    ForEach(Array(Curriculum.units.enumerated()), id: \.element.id) { idx, unit in
                        UnitSection(unit: unit, index: idx, start: start)
                    }
                    Text(tr("Weitere Kapitel folgen mit Updates. 🏔️", "More chapters coming with updates. 🏔️"))
                        .font(.rounded(.footnote))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Schwiizerdüütsch")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showStreak) { StreakSheet().presentationDetents([.medium]) }
            .onAppear {
                #if DEBUG
                let args = ProcessInfo.processInfo.arguments
                if let i = args.firstIndex(of: "-lesson"), i + 1 < args.count, let l = Curriculum.lesson(args[i + 1]) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { activeLesson = l }
                }
                #endif
            }
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson, mode: .lesson)
        }
    }

    private func isLocked(_ unit: Unit) -> Bool { !unit.isFree && !purchases.isPremium }

    func start(_ lesson: Lesson) {
        guard let unit = Curriculum.unit(lesson.unitID) else { return }
        if isLocked(unit) {
            router.showPaywall("locked-\(unit.id)")
        } else {
            activeLesson = lesson
        }
    }
}


// MARK: - Stats bar

struct StatsBar: View {
    @EnvironmentObject var store: ProgressStore
    @Binding var showStreak: Bool

    var body: some View {
        HStack(spacing: 10) {
            Button { showStreak = true } label: {
                pill(icon: "flame.fill", color: store.studiedToday ? Theme.orange : Theme.muted, text: "\(store.streak)")
            }
            .buttonStyle(.plain)
            pill(icon: "bolt.fill", color: Theme.gold, text: "\(store.state.xp) XP")
            Spacer()
            GoalRing(progress: store.goalProgress)
                .frame(width: 44, height: 44)
                .overlay(
                    Text("\(store.todayXP)")
                        .font(.rounded(size: 12, .bold))
                        .foregroundStyle(Theme.ink)
                )
                .accessibilityLabel(tr("Tagesziel", "Daily goal"))
                .accessibilityValue("\(store.todayXP) / \(store.state.dailyGoalXP) XP")
        }
        .padding(.top, 8)
    }

    private func pill(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(text).font(.rounded(.subheadline, .bold)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.line, lineWidth: 1.5))
    }
}

struct GoalRing: View {
    var progress: Double
    var body: some View {
        ZStack {
            Circle().stroke(Theme.line, lineWidth: 5)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(progress >= 1 ? Theme.green : Theme.red, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring, value: progress)
        }
    }
}

struct StreakSheet: View {
    @EnvironmentObject var store: ProgressStore
    var body: some View {
        VStack(spacing: 18) {
            Text("🔥").font(.system(size: 64))
            Text(trf("%d Tage Serie", "%d day streak", store.streak))
                .font(.rounded(.title, .heavy))
            Text(store.studiedToday
                 ? tr("Super – du hast heute schon gelernt!", "Great – you've already learned today!")
                 : tr("Mach heute eine Lektion, damit deine Serie weiterläuft.", "Do a lesson today to keep your streak going."))
                .font(.rounded(.subheadline))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                ForEach(Array(store.weekActivity.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().fill(d.active ? Theme.orange : Theme.soft).frame(width: 34, height: 34)
                            if d.active { Image(systemName: "checkmark").font(.system(size: 14, weight: .bold)).foregroundStyle(.white) }
                        }
                        .overlay(Circle().stroke(d.isToday ? Theme.red : .clear, lineWidth: 2).padding(-3))
                        Text(d.label).font(.rounded(.caption2, .semibold)).foregroundStyle(Theme.muted)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
}

// MARK: - Continue card

struct ContinueCard: View {
    @EnvironmentObject var store: ProgressStore
    var start: (Lesson) -> Void

    var body: some View {
        if let lesson = store.nextLesson, let unit = Curriculum.unit(lesson.unitID) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text(unit.emoji).font(.system(size: 34))
                        .frame(width: 58, height: 58)
                        .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.state.completedLessons.isEmpty ? tr("Los geht's!", "Let's go!") : tr("Weiter geht's", "Continue"))
                            .font(.rounded(.caption, .bold)).textCase(.uppercase).opacity(0.85)
                        Text(unit.title).font(.rounded(.title3, .heavy))
                        Text(trf("Lektion %d von %d", "Lesson %d of %d", lesson.index + 1, unit.lessons.count))
                            .font(.rounded(.footnote, .medium)).opacity(0.85)
                    }
                    Spacer(minLength: 0)
                }
                Button { start(lesson) } label: {
                    Text(tr("Lektion starten", "Start lesson")).textCase(.uppercase)
                }
                .buttonStyle(ChunkyButtonStyle(color: .white, deep: .white.opacity(0.55), textColor: unit.color))
            }
            .foregroundStyle(.white)
            .padding(18)
            .background(
                LinearGradient(colors: [unit.color, unit.color.opacity(0.75)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        } else {
            VStack(spacing: 8) {
                Text("🏆").font(.system(size: 44))
                Text(tr("Alles geschafft!", "All done!")).font(.rounded(.title3, .heavy))
                Text(tr("Du hast alle Kapitel abgeschlossen. Wiederhole im Üben-Tab!", "You've completed every chapter. Review in the Practice tab!"))
                    .font(.rounded(.subheadline)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).card()
        }
    }
}

// MARK: - Phrase of the day

struct PhraseOfTheDayCard: View {
    @EnvironmentObject var store: ProgressStore
    @ObservedObject private var speech = SpeechService.shared
    let phrase = Curriculum.phraseOfTheDay()

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Label(tr("Wort vom Tag", "Phrase of the day"), systemImage: "sun.max.fill")
                    .font(.rounded(.caption, .bold)).foregroundStyle(Theme.gold).textCase(.uppercase)
                Text(phrase.ch).font(.rounded(.title2, .heavy)).foregroundStyle(Theme.ink)
                Text(phrase.translation).font(.rounded(.subheadline)).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
            Button { SpeechService.shared.speak(phrase.ch) } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Theme.blue, in: Circle())
            }
            .accessibilityLabel(tr("Anhören", "Listen"))
        }
        .card()
    }
}

// MARK: - Unit path

struct UnitSection: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    let unit: Unit
    let index: Int
    var start: (Lesson) -> Void

    private var locked: Bool { !unit.isFree && !purchases.isPremium }
    private let offsets: [CGFloat] = [0, 46, 66, 46, 0, -46, -66, -46]

    var body: some View {
        VStack(spacing: 22) {
            header
            let current = store.nextLesson?.id
            ForEach(Array(unit.lessons.enumerated()), id: \.element.id) { i, lesson in
                LessonNode(
                    emoji: unit.emoji,
                    color: unit.color,
                    state: nodeState(lesson, current: current),
                    title: trf("Lektion %d", "Lesson %d", i + 1)
                ) { start(lesson) }
                .offset(x: offsets[(index * 3 + i) % offsets.count])
            }
        }
    }

    private func nodeState(_ lesson: Lesson, current: String?) -> LessonNode.NodeState {
        if store.isCompleted(lesson) { return .done }
        if locked { return .locked }
        return lesson.id == current ? .current : .open
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(trf("Kapitel %d", "Chapter %d", index + 1))
                        .font(.rounded(.caption, .bold)).textCase(.uppercase).opacity(0.85)
                    if !unit.isFree {
                        Text("PREMIUM")
                            .font(.rounded(size: 10, .heavy))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(.white.opacity(0.25), in: Capsule())
                    }
                }
                Text(unit.title).font(.rounded(.title3, .heavy))
                Text(unit.subtitle).font(.rounded(.footnote)).opacity(0.9)
            }
            Spacer(minLength: 8)
            if locked {
                Image(systemName: "lock.fill").font(.title3)
            } else {
                Text("\(store.completedCount(in: unit))/\(unit.lessons.count)")
                    .font(.rounded(.subheadline, .bold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.white.opacity(0.22), in: Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(unit.color, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }
}

struct LessonNode: View {
    enum NodeState { case done, current, open, locked }
    let emoji: String
    let color: Color
    let state: NodeState
    let title: String
    var action: () -> Void
    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if state == .current {
                    Circle().stroke(color.opacity(0.35), lineWidth: 6)
                        .frame(width: 96, height: 96)
                        .scaleEffect(pulse ? 1.08 : 0.96)
                        .opacity(pulse ? 0.4 : 1)
                }
                Circle().fill(deep).frame(width: 78, height: 78).offset(y: 5)
                Circle().fill(fill).frame(width: 78, height: 78)
                icon
            }
            .frame(width: 100, height: 100)
        }
        .buttonStyle(.plain)
        .onAppear {
            guard state == .current else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { pulse = true }
        }
        .accessibilityLabel(title)
        .accessibilityValue(stateLabel)
    }

    private var stateLabel: String {
        switch state {
        case .done: return tr("Abgeschlossen", "Completed")
        case .current: return tr("Nächste Lektion", "Next lesson")
        case .open: return tr("Verfügbar", "Available")
        case .locked: return tr("Gesperrt", "Locked")
        }
    }

    private var fill: Color {
        switch state {
        case .done: return Theme.gold
        case .current, .open: return color
        case .locked: return Theme.line
        }
    }
    private var deep: Color {
        switch state {
        case .done: return Color(hex: 0xC98C12)
        case .current, .open: return color.opacity(0.55)
        case .locked: return Theme.muted.opacity(0.35)
        }
    }

    @ViewBuilder private var icon: some View {
        switch state {
        case .done: Image(systemName: "checkmark").font(.system(size: 30, weight: .black)).foregroundStyle(.white)
        case .current: Image(systemName: "play.fill").font(.system(size: 30, weight: .black)).foregroundStyle(.white)
        case .open: Text(emoji).font(.system(size: 32))
        case .locked: Image(systemName: "lock.fill").font(.system(size: 26, weight: .bold)).foregroundStyle(Theme.muted)
        }
    }
}

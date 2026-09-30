import SwiftUI

extension UIColor {
    func darkened(_ amount: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(1, s * 1.05), brightness: b * (1 - amount), alpha: a)
    }
}

extension Color {
    func shaded(_ amount: CGFloat) -> Color { Color(UIColor(self).darkened(amount)) }
}

struct HomeView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @State private var activeLesson: Lesson?
    @State private var showStreak = false

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<11: return "Guete Morge"
        case 11..<17: return "Grüezi"
        default: return "Guete Abig"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Theme.bg.ignoresSafeArea()
                MountainScene()
                    .frame(height: 360)
                    .ignoresSafeArea(edges: .top)

                ScrollView {
                    VStack(spacing: 0) {
                        header
                        VStack(spacing: 26) {
                            ContinueCard(start: start)
                            PhraseOfTheDayCard()
                            LearningPath(start: start)
                            Text(tr("Weitere Kapitel folgen mit Updates. 🏔️", "More chapters coming with updates. 🏔️"))
                                .font(.ui(.footnote)).foregroundStyle(Theme.muted).padding(.top, 4)
                        }
                        .padding(.horizontal, 20).padding(.top, 26).padding(.bottom, 40)
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
            .sheet(isPresented: $showStreak) { StreakSheet().presentationDetents([.medium]).presentationCornerRadius(32) }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Button { showStreak = true } label: {
                    GlassPill(systemName: "flame.fill", tint: store.studiedToday ? Theme.gold : .white.opacity(0.7), text: "\(store.streak)")
                }
                .buttonStyle(.plain)
                GlassPill(systemName: "bolt.fill", tint: Theme.gold, text: "\(store.state.xp)")
                Spacer()
                GoalRing(progress: store.goalProgress, track: .white.opacity(0.28), fill: .white)
                    .frame(width: 42, height: 42)
                    .overlay(Text("\(store.todayXP)").font(.numeric(12)).foregroundStyle(.white))
                    .accessibilityLabel(tr("Tagesziel", "Daily goal"))
                    .accessibilityValue("\(store.todayXP) / \(store.state.dailyGoalXP) XP")
            }
            Spacer(minLength: 0)
            Text(greeting)
                .font(.display(44, .heavy)).foregroundStyle(.white)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 3)
            Text(store.studiedToday
                 ? tr("Schön, bisch hüt scho debii.", "Nice – you've already learned today.")
                 : tr("Was lehre mir hüt?", "What shall we learn today?"))
                .font(.ui(.subheadline, .semibold)).foregroundStyle(.white.opacity(0.92))
                .padding(.top, 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8).padding(.bottom, 34)
        .frame(height: 250)
    }

    private func isLocked(_ unit: Unit) -> Bool { !unit.isFree && !purchases.isPremium }

    func start(_ lesson: Lesson) {
        guard let unit = Curriculum.unit(lesson.unitID) else { return }
        if isLocked(unit) { router.showPaywall("locked-\(unit.id)") } else { activeLesson = lesson }
    }
}

// MARK: - Goal ring & streak

struct GoalRing: View {
    var progress: Double
    var track: Color = Theme.line
    var fill: Color = Theme.red
    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: 5)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(progress >= 1 ? Theme.green : fill, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6), value: progress)
        }
    }
}

struct StreakSheet: View {
    @EnvironmentObject var store: ProgressStore
    var body: some View {
        VStack(spacing: 18) {
            Text("🔥").font(.system(size: 64))
            Text(trf("%d Tage Serie", "%d day streak", store.streak)).font(.display(30, .heavy)).foregroundStyle(Theme.ink)
            Text(store.studiedToday
                 ? tr("Super – du hast heute schon gelernt!", "Great – you've already learned today!")
                 : tr("Mach heute eine Lektion, damit deine Serie weiterläuft.", "Do a lesson today to keep your streak going."))
                .font(.ui(.subheadline)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            HStack(spacing: 10) {
                ForEach(Array(store.weekActivity.enumerated()), id: \.offset) { _, d in
                    VStack(spacing: 7) {
                        ZStack {
                            Circle().fill(d.active ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.orange], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(Theme.soft))
                                .frame(width: 36, height: 36)
                            if d.active { Image(systemName: "checkmark").font(.system(size: 14, weight: .black)).foregroundStyle(.white) }
                        }
                        .overlay(Circle().stroke(d.isToday ? Theme.red : .clear, lineWidth: 2).padding(-4))
                        Text(d.label).font(.ui(.caption2, .semibold)).foregroundStyle(Theme.muted)
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
            ZStack(alignment: .topTrailing) {
                Text(unit.emoji).font(.system(size: 104)).opacity(0.2).rotationEffect(.degrees(12)).offset(x: 20, y: -34)
                VStack(alignment: .leading, spacing: 14) {
                    Text(store.state.completedLessons.isEmpty ? tr("Los geht's", "Let's go") : tr("Weiter geht's", "Continue")).eyebrow(.white.opacity(0.85))
                    Text(unit.title).font(.display(28, .heavy)).foregroundStyle(.white).lineLimit(2)
                    HStack(spacing: 10) {
                        ProgressBar(value: store.progress(of: unit), color: .white, track: .white.opacity(0.28), height: 8)
                        Text(trf("Lektion %d von %d", "Lesson %d of %d", lesson.index + 1, unit.lessons.count))
                            .font(.ui(.footnote, .semibold)).foregroundStyle(.white.opacity(0.9)).fixedSize()
                    }
                    Button { start(lesson) } label: { Text(tr("Lektion starten", "Start lesson")).textCase(.uppercase) }
                        .buttonStyle(ChunkyButtonStyle(color: .white, deep: Color.white.opacity(0.86), textColor: unit.color.shaded(0.15)))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(22)
            .background(
                LinearGradient(colors: [unit.color, unit.color.shaded(0.32)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 30, style: .continuous)
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: unit.color.opacity(0.35), radius: 22, y: 12)
        } else {
            VStack(spacing: 8) {
                Text("🏆").font(.system(size: 48))
                Text(tr("Alles geschafft!", "All done!")).font(.display(24))
                Text(tr("Du hast alle Kapitel abgeschlossen. Wiederhole im Üben-Tab!", "You've completed every chapter. Review in the Practice tab!"))
                    .font(.ui(.subheadline)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).card(padding: 24)
        }
    }
}

// MARK: - Phrase of the day

struct PhraseOfTheDayCard: View {
    let phrase = Curriculum.phraseOfTheDay()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(tr("Wort vom Tag", "Phrase of the day"), systemImage: "sun.max.fill")
                    .font(.ui(.caption, .bold)).tracking(1).textCase(.uppercase).foregroundStyle(Theme.gold)
                Spacer()
                if SpeechService.shared.hasRecording(for: phrase.ch) { SpeakButton(text: phrase.ch, size: 36) }
                ShareLink(item: "«\(phrase.ch)» = \(phrase.translation) 🇨🇭 \(AppLinks.appStore.absoluteString)") {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.muted)
                        .frame(width: 36, height: 36).background(Theme.soft, in: Circle())
                }
                .accessibilityLabel(tr("Teilen", "Share"))
            }
            Text("«\(phrase.ch)»").font(.display(28, .bold)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            Text(phrase.translation).font(.ui(.subheadline)).foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 20)
    }
}

// MARK: - Learning path

struct LearningPath: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    var start: (Lesson) -> Void
    private let offsets: [CGFloat] = [0, 54, 80, 54, 0, -54, -80, -54]

    var body: some View {
        let current = store.nextLesson?.id
        VStack(spacing: 0) {
            ForEach(Array(Curriculum.units.enumerated()), id: \.element.id) { idx, unit in
                let locked = !unit.isFree && !purchases.isPremium
                UnitBanner(unit: unit, index: idx, locked: locked)
                    .padding(.top, idx == 0 ? 0 : 30)
                    .padding(.bottom, 22)
                ForEach(Array(unit.lessons.enumerated()), id: \.element.id) { i, lesson in
                    let x = offsets[(idx * 3 + i) % offsets.count]
                    if i > 0 {
                        let prev = offsets[(idx * 3 + i - 1) % offsets.count]
                        Connector(from: prev, to: x, color: unit.color.opacity(store.isCompleted(unit.lessons[i - 1]) ? 0.7 : 0.25))
                    }
                    LessonNode(
                        emoji: unit.emoji, color: unit.color,
                        state: state(lesson, locked: locked, current: current),
                        title: trf("Lektion %d", "Lesson %d", i + 1)
                    ) { start(lesson) }
                    .offset(x: x)
                }
            }
        }
    }

    private func state(_ lesson: Lesson, locked: Bool, current: String?) -> LessonNode.NodeState {
        if store.isCompleted(lesson) { return .done }
        if locked { return .locked }
        return lesson.id == current ? .current : .open
    }
}

struct Connector: View {
    let from: CGFloat
    let to: CGFloat
    let color: Color
    var body: some View {
        GeometryReader { g in
            Path { p in
                let mid = g.size.width / 2
                p.move(to: CGPoint(x: mid + from, y: 0))
                p.addCurve(to: CGPoint(x: mid + to, y: g.size.height),
                           control1: CGPoint(x: mid + from, y: g.size.height * 0.65),
                           control2: CGPoint(x: mid + to, y: g.size.height * 0.35))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0.1, 11]))
        }
        .frame(height: 36)
        .accessibilityHidden(true)
    }
}

struct UnitBanner: View {
    @EnvironmentObject var store: ProgressStore
    let unit: Unit
    let index: Int
    let locked: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            Text(unit.emoji).font(.system(size: 92)).opacity(locked ? 0.12 : 0.26).rotationEffect(.degrees(-10)).offset(x: 10, y: 6)
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(trf("Kapitel %d", "Chapter %d", index + 1)).eyebrow(.white.opacity(0.85))
                        if !unit.isFree {
                            Text("PREMIUM").font(.ui(size: 9, .heavy)).tracking(0.8)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(.white.opacity(0.22), in: Capsule())
                        }
                    }
                    Text(unit.title).font(.display(23, .heavy)).fixedSize(horizontal: false, vertical: true)
                    Text(unit.subtitle).font(.ui(.footnote)).opacity(0.88)
                }
                Spacer(minLength: 8)
                if locked {
                    Image(systemName: "lock.fill").font(.title3).padding(12).background(.white.opacity(0.2), in: Circle())
                } else {
                    Text("\(store.completedCount(in: unit))/\(unit.lessons.count)")
                        .font(.numeric(14)).padding(.horizontal, 12).padding(.vertical, 7)
                        .background(.white.opacity(0.2), in: Capsule())
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(
            LinearGradient(colors: locked ? [unit.color.opacity(0.55), unit.color.shaded(0.3).opacity(0.55)] : [unit.color, unit.color.shaded(0.3)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: unit.color.opacity(locked ? 0.1 : 0.3), radius: 16, y: 8)
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
                    Circle().stroke(color.opacity(0.35), lineWidth: 5)
                        .frame(width: 100, height: 100)
                        .scaleEffect(pulse ? 1.12 : 0.94).opacity(pulse ? 0 : 1)
                }
                Circle().fill(fill).frame(width: 80, height: 80)
                    .overlay(Circle().strokeBorder(rim, lineWidth: state == .open ? 3 : 0))
                    .overlay(Circle().strokeBorder(LinearGradient(colors: [.white.opacity(state == .locked || state == .open ? 0 : 0.5), .clear], startPoint: .top, endPoint: .center), lineWidth: 1.5))
                    .shadow(color: glow, radius: 14, y: 8)
                icon
                if state == .current {
                    Text("START").font(.ui(size: 11, .heavy)).tracking(1)
                        .foregroundStyle(color.shaded(0.2)).padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.card, in: Capsule()).shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                        .offset(y: -58)
                }
            }
            .frame(width: 104, height: 104)
        }
        .buttonStyle(NodePressStyle())
        .onAppear {
            guard state == .current else { return }
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) { pulse = true }
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

    private var fill: AnyShapeStyle {
        switch state {
        case .done: return AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xFFC94D), Theme.goldDeep], startPoint: .top, endPoint: .bottom))
        case .current: return AnyShapeStyle(LinearGradient(colors: [color, color.shaded(0.3)], startPoint: .top, endPoint: .bottom))
        case .open: return AnyShapeStyle(Theme.card)
        case .locked: return AnyShapeStyle(Theme.soft)
        }
    }
    private var rim: Color { state == .open ? color.opacity(0.5) : .clear }
    private var glow: Color {
        switch state {
        case .done: return Theme.gold.opacity(0.45)
        case .current: return color.opacity(0.45)
        case .open: return .black.opacity(0.08)
        case .locked: return .clear
        }
    }

    @ViewBuilder private var icon: some View {
        switch state {
        case .done: Image(systemName: "checkmark").font(.system(size: 30, weight: .black)).foregroundStyle(.white)
        case .current: Image(systemName: "play.fill").font(.system(size: 28, weight: .black)).foregroundStyle(.white).offset(x: 2)
        case .open: Text(emoji).font(.system(size: 34))
        case .locked: Image(systemName: "lock.fill").font(.system(size: 24, weight: .bold)).foregroundStyle(Theme.muted)
        }
    }
}

struct NodePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

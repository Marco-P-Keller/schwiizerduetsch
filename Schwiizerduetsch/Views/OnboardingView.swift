import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var router: AppRouter
    @State private var step = 0
    @State private var reminderTime = Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date()) ?? Date()
    private let lastStep = 5

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if step == 0 {
                welcome.transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        Button { withAnimation(.spring(response: 0.4)) { step -= 1 } } label: {
                            Image(systemName: "chevron.left").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.muted)
                                .frame(width: 38, height: 38).background(Theme.soft, in: Circle())
                        }
                        .accessibilityLabel(tr("Zurück", "Back"))
                        ProgressBar(value: Double(step) / Double(lastStep), color: Theme.red, height: 10)
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                    Group {
                        switch step {
                        case 1: reasonStep
                        case 2: levelStep
                        case 3: goalStep
                        case 4: reminderStep
                        default: readyStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: step)
    }

    // MARK: Welcome

    private var welcome: some View {
        VStack(spacing: 0) {
            ZStack {
                MountainScene().ignoresSafeArea(edges: .top)
                VStack(spacing: 14) {
                    Spacer()
                    AppMark(size: 104)
                    Text("Schwiizerdüütsch").font(.display(34, .heavy)).foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 3)
                    Spacer().frame(height: 46)
                }
            }
            .frame(maxHeight: .infinity)

            VStack(spacing: 22) {
                Text(tr("Lerne Schweizerdeutsch – spielerisch, in 5 Minuten am Tag.",
                        "Learn Swiss German – playfully, in 5 minutes a day."))
                    .font(.ui(.title3, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                VStack(alignment: .leading, spacing: 14) {
                    feature("text.bubble.fill", Theme.red, tr("Echte Alltagssätze – von Grüezi bis Fiirabig", "Real everyday phrases – from Grüezi to Fiirabig"))
                    feature("map.fill", Theme.blue, tr("Zürcher, Berner & Basler Dialekt im Vergleich", "Zürich, Bern & Basel dialects compared"))
                    feature("flame.fill", Theme.orange, tr("Serien, Tagesziele und kleine Erfolge", "Streaks, daily goals and small wins"))
                }
                Button { withAnimation { step = 1 } } label: { Text(tr("Los geht's", "Get started")).textCase(.uppercase) }
                    .buttonStyle(.chunky)
                Text(tr("Für Neuzuzüger, Partner, Feriengäste und Neugierige.", "For newcomers, partners, visitors and the curious."))
                    .font(.ui(.footnote)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 10)
            .background(
                Theme.bg.clipShape(UnevenRoundedRectangle(topLeadingRadius: 32, topTrailingRadius: 32, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 24, y: -6)
                    .ignoresSafeArea(edges: .bottom)
            )
            .offset(y: -28)
        }
    }

    private func feature(_ icon: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, tint: tint, size: 42)
            Text(text).font(.ui(.subheadline, .semibold)).foregroundStyle(Theme.ink).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: Steps

    private var reasonStep: some View {
        choiceStep(
            title: tr("Warum möchtest du Schwiizerdüütsch lernen?", "Why do you want to learn Swiss German?"),
            options: [
                ("move", "🧳", tr("Ich ziehe in die Schweiz / habe hier einen Job", "I'm moving to Switzerland / have a job here")),
                ("partner", "❤️", tr("Partner:in, Familie oder Freunde", "Partner, family or friends")),
                ("work", "💼", tr("Für Kundschaft und Kolleg:innen", "For clients and colleagues")),
                ("travel", "🏔️", tr("Ferien und Reisen", "Holidays and travel")),
                ("fun", "🧀", tr("Aus Neugier und Spass", "Curiosity and fun")),
            ],
            selected: store.state.reason
        ) { store.state.reason = $0; step = 2 }
    }

    private var levelStep: some View {
        choiceStep(
            title: tr("Wie gut kannst du es schon?", "How much do you know already?"),
            options: [
                ("0", "🌱", tr("Ich fange ganz von vorne an", "I'm starting from scratch")),
                ("1", "🌿", tr("Ich verstehe ein paar Wörter", "I understand a few words")),
                ("2", "🌳", tr("Ich verstehe vieles, spreche aber nicht", "I understand a lot but don't speak")),
            ],
            selected: "\(store.state.level)"
        ) { store.state.level = Int($0) ?? 0; step = 3 }
    }

    private var goalStep: some View {
        choiceStep(
            title: tr("Wie viel Zeit möchtest du investieren?", "How much time do you want to invest?"),
            options: [
                ("30", "☕️", tr("Locker · 1 Lektion / Tag (~5 Min.)", "Casual · 1 lesson / day (~5 min)")),
                ("60", "🚴", tr("Regelmässig · 2 Lektionen / Tag (~10 Min.)", "Regular · 2 lessons / day (~10 min)")),
                ("120", "🚀", tr("Intensiv · 4 Lektionen / Tag (~20 Min.)", "Intense · 4 lessons / day (~20 min)")),
            ],
            selected: "\(store.state.dailyGoalXP)"
        ) { store.state.dailyGoalXP = Int($0) ?? 60; step = 4 }
    }

    private var reminderStep: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle().fill(Theme.gold.opacity(0.18)).frame(width: 120, height: 120)
                Text("🔔").font(.system(size: 58))
            }
            Text(tr("Wann soll ich dich erinnern?", "When should I remind you?"))
                .font(.display(30, .heavy)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            Text(tr("Wer täglich kurz lernt, bleibt am Ball. Du kannst das jederzeit ändern.",
                    "Short daily sessions keep you going. You can change this anytime."))
                .font(.ui(.body)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel).labelsHidden().frame(height: 130)
            Spacer()
            Button {
                Task {
                    let ok = await NotificationService.requestAuthorization()
                    let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                    store.state.reminderHour = c.hour ?? 18
                    store.state.reminderMinute = c.minute ?? 30
                    store.state.reminderEnabled = ok
                    if ok { await NotificationService.scheduleDailyReminders(hour: c.hour ?? 18, minute: c.minute ?? 30) }
                    step = 5
                }
            } label: { Text(tr("Erinnerung aktivieren", "Enable reminders")).textCase(.uppercase) }
                .buttonStyle(.chunky)
            Button(tr("Vielleicht später", "Maybe later")) { step = 5 }
                .font(.ui(.subheadline, .bold)).foregroundStyle(Theme.muted).padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🇨🇭").font(.system(size: 84)).shadow(color: .black.opacity(0.15), radius: 12, y: 8)
            Text(tr("Dein Lernpfad ist bereit!", "Your learning path is ready!"))
                .font(.display(32, .heavy)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 16) {
                summary("map.fill", Theme.blue, trf("%d Kapitel · %d Ausdrücke", "%d chapters · %d phrases", Curriculum.units.count, Curriculum.allPhrases.count))
                summary("target", Theme.red, trf("Tagesziel: %d XP", "Daily goal: %d XP", store.state.dailyGoalXP))
                summary("gift.fill", Theme.green, tr("Kapitel 1 & 2 sind gratis", "Chapters 1 & 2 are free"))
            }
            .frame(maxWidth: .infinity, alignment: .leading).card(padding: 20)
            Spacer()
            Button { finish() } label: { Text(tr("Lernpfad starten", "Start learning")).textCase(.uppercase) }
                .buttonStyle(.chunky)
        }
        .padding(.horizontal, 24).padding(.bottom, 8)
    }

    private func summary(_ icon: String, _ tint: Color, _ text: String) -> some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, tint: tint, size: 38)
            Text(text).font(.ui(.body, .semibold)).foregroundStyle(Theme.ink)
        }
    }

    private func finish() {
        store.state.onboardingDone = true
        // Show the paywall at the moment of highest intent — dismissible, with free trial.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { router.showPaywall("onboarding") }
    }

    // MARK: Generic choice screen

    private func choiceStep(title: String, options: [(String, String, String)], selected: String,
                            onSelect: @escaping (String) -> Void) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(title).font(.display(30, .heavy)).foregroundStyle(Theme.ink).padding(.top, 26).padding(.bottom, 8)
                ForEach(options, id: \.0) { opt in
                    let isSel = opt.0 == selected
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        onSelect(opt.0)
                    } label: {
                        HStack(spacing: 14) {
                            Text(opt.1).font(.system(size: 28)).frame(width: 52, height: 52)
                                .background(Theme.soft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            Text(opt.2).font(.ui(.body, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            if isSel { Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(Theme.red) }
                        }
                        .padding(14)
                        .background(isSel ? Theme.red.opacity(0.06) : Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(isSel ? Theme.red : Theme.line, lineWidth: isSel ? 2 : 1.2))
                        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                    }
                    .buttonStyle(OptionPressStyle())
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }
}

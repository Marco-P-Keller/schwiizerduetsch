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
            VStack(spacing: 0) {
                if step > 0 {
                    HStack(spacing: 14) {
                        Button { withAnimation { step -= 1 } } label: {
                            Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundStyle(Theme.muted)
                                .frame(width: 36, height: 36)
                        }
                        .accessibilityLabel(tr("Zurück", "Back"))
                        ProgressBar(value: Double(step) / Double(lastStep), color: Theme.red)
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                }
                Group {
                    switch step {
                    case 0: welcome
                    case 1: reasonStep
                    case 2: levelStep
                    case 3: goalStep
                    case 4: reminderStep
                    default: readyStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                .id(step)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
    }

    // MARK: Steps

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0xFF3B47), Color(hex: 0xC8101E)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 150, height: 150)
                    .shadow(color: Theme.red.opacity(0.35), radius: 24, y: 12)
                Text("ü").font(.system(size: 110, weight: .heavy, design: .rounded)).foregroundStyle(.white).offset(y: -4)
            }
            Text("Grüezi!").font(.rounded(size: 44, .heavy)).foregroundStyle(Theme.ink)
            Text(tr("Lerne Schwiizerdüütsch – spielerisch, in 5 Minuten am Tag.",
                    "Learn Swiss German – playfully, in 5 minutes a day."))
                .font(.rounded(.title3, .medium)).foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center).padding(.horizontal, 28)
            VStack(alignment: .leading, spacing: 12) {
                feature("🎧", tr("Hör, wie es klingt", "Hear how it sounds"))
                feature("🧩", tr("Übe mit Sätzen aus dem Alltag", "Practise real everyday phrases"))
                feature("🗺️", tr("Entdecke Zürcher, Berner & Basler Dialekt", "Explore Zürich, Bern & Basel dialects"))
            }
            .padding(.top, 8)
            Spacer()
            Button { withAnimation { step = 1 } } label: { Text(tr("Los geht's", "Get started")).textCase(.uppercase) }
                .buttonStyle(.chunky).padding(.horizontal, 24)
            Text(tr("Für Neuzuzüger, Partner, Feriengäste und Neugierige.", "For newcomers, partners, visitors and the curious."))
                .font(.rounded(.footnote)).foregroundStyle(Theme.muted).padding(.bottom, 8)
        }
    }

    private func feature(_ emoji: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.title2).frame(width: 40, height: 40)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(text).font(.rounded(.body, .semibold)).foregroundStyle(Theme.ink)
        }
    }

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
        ) { store.state.reason = $0; withAnimation { step = 2 } }
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
        ) { store.state.level = Int($0) ?? 0; withAnimation { step = 3 } }
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
        ) { store.state.dailyGoalXP = Int($0) ?? 60; withAnimation { step = 4 } }
    }

    private var reminderStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🔔").font(.system(size: 72))
            Text(tr("Wann soll ich dich erinnern?", "When should I remind you?"))
                .font(.rounded(.title, .heavy)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            Text(tr("Wer täglich kurz lernt, bleibt am Ball. Du kannst das jederzeit ändern.",
                    "Short daily sessions keep you going. You can change this anytime."))
                .font(.rounded(.body)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
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
                    withAnimation { step = 5 }
                }
            } label: { Text(tr("Erinnerung aktivieren", "Enable reminders")).textCase(.uppercase) }
                .buttonStyle(.chunky)
            Button(tr("Vielleicht später", "Maybe later")) { withAnimation { step = 5 } }
                .font(.rounded(.subheadline, .bold)).foregroundStyle(Theme.muted).padding(.bottom, 8)
        }
        .padding(.horizontal, 24)
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🇨🇭").font(.system(size: 80))
            Text(tr("Dein Lernpfad ist bereit!", "Your learning path is ready!"))
                .font(.rounded(.title, .heavy)).multilineTextAlignment(.center).foregroundStyle(Theme.ink)
            VStack(alignment: .leading, spacing: 12) {
                summary("map.fill", trf("%d Kapitel · %d Ausdrücke", "%d chapters · %d phrases", Curriculum.units.count, Curriculum.allPhrases.count))
                summary("target", trf("Tagesziel: %d XP", "Daily goal: %d XP", store.state.dailyGoalXP))
                summary("gift.fill", tr("Kapitel 1 & 2 sind gratis", "Chapters 1 & 2 are free"))
            }
            .frame(maxWidth: .infinity, alignment: .leading).card(padding: 18)
            Spacer()
            Button { finish() } label: { Text(tr("Lernpfad starten", "Start learning")).textCase(.uppercase) }
                .buttonStyle(.chunky)
        }
        .padding(.horizontal, 24).padding(.bottom, 8)
    }

    private func summary(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 26)
            Text(text).font(.rounded(.body, .semibold)).foregroundStyle(Theme.ink)
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
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(.rounded(.title, .heavy)).foregroundStyle(Theme.ink).padding(.top, 24)
            ForEach(options, id: \.0) { opt in
                Button { onSelect(opt.0) } label: {
                    HStack(spacing: 14) {
                        Text(opt.1).font(.title)
                        Text(opt.2).font(.rounded(.body, .semibold)).foregroundStyle(Theme.ink).multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(opt.0 == selected ? Theme.red : Theme.line, lineWidth: 2))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

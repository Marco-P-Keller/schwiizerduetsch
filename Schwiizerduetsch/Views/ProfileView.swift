import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @State private var showManage = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            ScreenScaffold(title: tr("Profil", "Profile"), subtitle: trf("Level %d · %d XP", "Level %d · %d XP", store.level, store.state.xp)) {
                statsGrid
                levelCard
                if !purchases.isPremium { premiumBanner }
                achievements
                settings
                Text("Grüezi · \(Bundle.main.version)").font(.ui(.footnote)).foregroundStyle(Theme.muted).padding(.top, 6)
            }
            .manageSubscriptionsSheet(isPresented: $showManage)
            .onAppear {
                reminderTime = Calendar.current.date(bySettingHour: store.state.reminderHour, minute: store.state.reminderMinute, second: 0, of: Date()) ?? Date()
            }
        }
    }

    // MARK: Stats

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            statTile("flame.fill", Theme.orange, "\(store.streak)", tr("Tage Serie", "Day streak"))
            statTile("bolt.fill", Theme.gold, "\(store.state.xp)", "XP")
            statTile("text.book.closed.fill", Theme.blue, "\(store.state.seenPhrases.count)", tr("Ausdrücke", "Phrases"))
            statTile("checkmark.seal.fill", Theme.green, "\(store.completedUnits)/\(Curriculum.units.count)", tr("Kapitel", "Chapters"))
        }
    }

    private func statTile(_ icon: String, _ color: Color, _ value: String, _ label: String) -> some View {
        HStack(spacing: 12) {
            IconBadge(systemName: icon, tint: color, size: 42)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.numeric(22)).foregroundStyle(Theme.ink)
                Text(label).font(.ui(.caption, .semibold)).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 14)
    }

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(trf("Level %d", "Level %d", store.level)).font(.display(20, .heavy)).foregroundStyle(Theme.ink)
                Spacer()
                Text("\(store.state.xp % 120)/120 XP").font(.numeric(13)).foregroundStyle(Theme.muted)
            }
            ProgressBar(value: store.levelProgress, color: Theme.gold, height: 12)
        }
        .card(padding: 18)
    }

    private var premiumBanner: some View {
        Button { router.showPaywall("profile") } label: {
            ZStack(alignment: .trailing) {
                MountainScene(fadeTo: Color(hex: 0x3D3876), showSun: true).frame(height: 140).opacity(0.95)
                LinearGradient(colors: [Color.black.opacity(0.38), .clear], startPoint: .leading, endPoint: .trailing)
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tr("Premium freischalten", "Unlock Premium")).font(.display(22, .heavy))
                        Text(tr("Alle Kapitel · Dialekte · Wiederholung", "All chapters · Dialects · Review")).font(.ui(.footnote, .semibold)).opacity(0.92)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.headline)
                }
                .foregroundStyle(.white).padding(20)
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: Theme.red.opacity(0.3), radius: 18, y: 10)
        }
        .buttonStyle(OptionPressStyle())
    }

    // MARK: Achievements

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(tr("Erfolge", "Achievements")).font(.display(22, .heavy)).foregroundStyle(Theme.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(store.achievements) { a in
                    VStack(spacing: 8) {
                        Text(a.emoji).font(.system(size: 32)).grayscale(a.unlocked ? 0 : 1).opacity(a.unlocked ? 1 : 0.3)
                            .shadow(color: a.unlocked ? Theme.gold.opacity(0.5) : .clear, radius: 8, y: 3)
                        Text(a.title).font(.ui(.caption, .bold)).foregroundStyle(a.unlocked ? Theme.ink : Theme.muted)
                            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 92).padding(8)
                    .background(a.unlocked ? Theme.gold.opacity(0.13) : Theme.soft, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(a.unlocked ? Theme.gold.opacity(0.35) : .clear, lineWidth: 1))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(a.title)
                    .accessibilityValue(a.unlocked ? tr("Freigeschaltet", "Unlocked") : a.detail)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card(padding: 20)
    }

    // MARK: Settings

    private var settings: some View {
        VStack(spacing: 0) {
            settingRow(icon: "target", tint: Theme.red, title: tr("Tagesziel", "Daily goal")) {
                Picker("", selection: $store.state.dailyGoalXP) {
                    Text("30 XP").tag(30); Text("60 XP").tag(60); Text("120 XP").tag(120)
                }.labelsHidden()
            }
            divider
            settingRow(icon: "bell.fill", tint: Theme.gold, title: tr("Tägliche Erinnerung", "Daily reminder")) {
                Toggle("", isOn: Binding(get: { store.state.reminderEnabled }, set: setReminder)).labelsHidden().tint(Theme.red)
            }
            if store.state.reminderEnabled {
                divider
                settingRow(icon: "clock.fill", tint: Theme.orange, title: tr("Zeit", "Time")) {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute).labelsHidden()
                        .onChange(of: reminderTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            store.state.reminderHour = c.hour ?? 18; store.state.reminderMinute = c.minute ?? 30
                            Task { await NotificationService.scheduleDailyReminders(hour: c.hour ?? 18, minute: c.minute ?? 30) }
                        }
                }
            }
            if SpeechService.shared.anyRecordings {
                divider
                settingRow(icon: "speaker.wave.2.fill", tint: Theme.blue, title: tr("Automatisch abspielen", "Autoplay audio")) {
                    Toggle("", isOn: $store.state.autoplay).labelsHidden().tint(Theme.red)
                }
            }
            divider
            settingRow(icon: "globe", tint: Theme.green, title: tr("Übersetzungssprache", "Translation language")) {
                Picker("", selection: Binding(get: { store.language }, set: { store.language = $0 })) {
                    ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
                }.labelsHidden()
            }
            divider
            if purchases.isPremium {
                linkRow(icon: "crown.fill", tint: Theme.gold, title: tr("Abo verwalten", "Manage subscription")) { showManage = true }
            } else {
                linkRow(icon: "crown.fill", tint: Theme.gold, title: tr("Premium freischalten", "Unlock Premium")) { router.showPaywall("settings") }
            }
            divider
            linkRow(icon: "arrow.clockwise", tint: Theme.blue, title: tr("Käufe wiederherstellen", "Restore purchases")) { Task { await purchases.restore() } }
            divider
            linkRow(icon: "star.fill", tint: Theme.gold, title: tr("App bewerten", "Rate the app")) { UIApplication.shared.open(AppLinks.review) }
            divider
            ShareLink(item: AppLinks.appStore, message: Text(tr("Lerne Schwiizerdüütsch mit dieser App 🇨🇭", "Learn Swiss German with this app 🇨🇭"))) {
                rowLabel(icon: "square.and.arrow.up", tint: Theme.green, title: tr("App teilen", "Share the app"))
            }
            divider
            linkRow(icon: "questionmark.circle.fill", tint: Theme.blue, title: tr("Hilfe & Feedback", "Help & feedback")) { UIApplication.shared.open(AppLinks.support) }
            divider
            linkRow(icon: "hand.raised.fill", tint: Theme.muted, title: tr("Datenschutz", "Privacy Policy")) { UIApplication.shared.open(AppLinks.privacy) }
            divider
            linkRow(icon: "doc.text.fill", tint: Theme.muted, title: tr("Nutzungsbedingungen", "Terms of Use")) { UIApplication.shared.open(AppLinks.terms) }
        }
        .card(padding: 6)
        .alert(tr("Hinweis", "Note"), isPresented: Binding(get: { purchases.errorMessage != nil }, set: { if !$0 { purchases.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(purchases.errorMessage ?? "") }
    }

    private var divider: some View { Divider().padding(.leading, 66) }

    private func setReminder(_ on: Bool) {
        if on {
            Task {
                let ok = await NotificationService.requestAuthorization()
                store.state.reminderEnabled = ok
                if ok { await NotificationService.scheduleDailyReminders(hour: store.state.reminderHour, minute: store.state.reminderMinute) }
                else if let url = URL(string: UIApplication.openSettingsURLString) { await UIApplication.shared.open(url) }
            }
        } else {
            store.state.reminderEnabled = false
            NotificationService.cancelDailyReminders()
        }
    }

    private func rowLabel(icon: String, tint: Color, title: String) -> some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, tint: tint, size: 36)
            Text(title).font(.ui(.body, .medium)).foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.muted.opacity(0.6))
        }
        .padding(.horizontal, 14).padding(.vertical, 10).contentShape(Rectangle())
    }

    private func linkRow(icon: String, tint: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(icon: icon, tint: tint, title: title) }.buttonStyle(.plain)
    }

    private func settingRow<C: View>(icon: String, tint: Color, title: String, @ViewBuilder trailing: () -> C) -> some View {
        HStack(spacing: 14) {
            IconBadge(systemName: icon, tint: tint, size: 36)
            Text(title).font(.ui(.body, .medium)).foregroundStyle(Theme.ink)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }
}

extension Bundle {
    var version: String {
        let v = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }
}

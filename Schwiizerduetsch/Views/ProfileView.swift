import SwiftUI
import StoreKit

struct ProfileView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @Environment(\.requestReview) private var requestReview
    @State private var showManage = false
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    header
                    if !purchases.isPremium { premiumBanner }
                    achievements
                    settings
                    Text("Grüezi · \(Bundle.main.version)").font(.rounded(.footnote)).foregroundStyle(Theme.muted).padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(tr("Profil", "Profile"))
            .manageSubscriptionsSheet(isPresented: $showManage)
            .onAppear {
                reminderTime = Calendar.current.date(bySettingHour: store.state.reminderHour, minute: store.state.reminderMinute, second: 0, of: Date()) ?? Date()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                statTile("flame.fill", Theme.orange, "\(store.streak)", tr("Tage Serie", "Day streak"))
                statTile("bolt.fill", Theme.gold, "\(store.state.xp)", "XP")
            }
            HStack(spacing: 12) {
                statTile("text.book.closed.fill", Theme.blue, "\(store.state.seenPhrases.count)", tr("Ausdrück", "Phrases"))
                statTile("star.fill", Theme.green, "\(store.level)", tr("Level", "Level"))
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(trf("Level %d", "Level %d", store.level)).font(.rounded(.subheadline, .bold)).foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(store.state.xp % 120)/120 XP").font(.rounded(.caption, .semibold)).foregroundStyle(Theme.muted)
                }
                ProgressBar(value: store.levelProgress, color: Theme.gold)
            }
            .card()
        }
    }

    private func statTile(_ icon: String, _ color: Color, _ value: String, _ label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundStyle(color).frame(width: 32)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.rounded(.title3, .heavy)).foregroundStyle(Theme.ink)
                Text(label).font(.rounded(.caption, .semibold)).foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
        }
        .card(padding: 14)
    }

    private var premiumBanner: some View {
        Button { router.showPaywall("profile") } label: {
            HStack(spacing: 14) {
                Text("🏔️").font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(tr("Premium freischalten", "Unlock Premium")).font(.rounded(.headline, .heavy))
                    Text(tr("Alle Kapitel · Dialekt-Explorer · Wiederholung", "All chapters · Dialect explorer · Review")).font(.rounded(.footnote)).opacity(0.9)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.white).padding(16)
            .background(LinearGradient(colors: [Color(hex: 0xFF3B47), Color(hex: 0xC8101E)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var achievements: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(tr("Erfolge", "Achievements")).font(.rounded(.headline, .heavy)).foregroundStyle(Theme.ink)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(store.achievements) { a in
                    VStack(spacing: 6) {
                        Text(a.emoji).font(.system(size: 30)).grayscale(a.unlocked ? 0 : 1).opacity(a.unlocked ? 1 : 0.35)
                        Text(a.title).font(.rounded(.caption, .bold)).foregroundStyle(a.unlocked ? Theme.ink : Theme.muted)
                            .multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity, minHeight: 84).padding(8)
                    .background(a.unlocked ? Theme.gold.opacity(0.14) : Theme.soft, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(a.title)
                    .accessibilityValue(a.unlocked ? tr("Freigeschaltet", "Unlocked") : a.detail)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }

    private var settings: some View {
        VStack(spacing: 0) {
            settingRow(icon: "target", title: tr("Tagesziel", "Daily goal")) {
                Picker("", selection: $store.state.dailyGoalXP) {
                    Text("30 XP").tag(30); Text("60 XP").tag(60); Text("120 XP").tag(120)
                }.labelsHidden()
            }
            Divider().padding(.leading, 52)
            settingRow(icon: "bell.fill", title: tr("Tägliche Erinnerung", "Daily reminder")) {
                Toggle("", isOn: Binding(get: { store.state.reminderEnabled }, set: setReminder)).labelsHidden()
            }
            if store.state.reminderEnabled {
                Divider().padding(.leading, 52)
                settingRow(icon: "clock.fill", title: tr("Zeit", "Time")) {
                    DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute).labelsHidden()
                        .onChange(of: reminderTime) { _, t in
                            let c = Calendar.current.dateComponents([.hour, .minute], from: t)
                            store.state.reminderHour = c.hour ?? 18; store.state.reminderMinute = c.minute ?? 30
                            Task { await NotificationService.scheduleDailyReminders(hour: c.hour ?? 18, minute: c.minute ?? 30) }
                        }
                }
            }
            Divider().padding(.leading, 52)
            settingRow(icon: "speaker.wave.2.fill", title: tr("Automatisch abspielen", "Autoplay audio")) {
                Toggle("", isOn: $store.state.autoplay).labelsHidden()
            }
            Divider().padding(.leading, 52)
            settingRow(icon: "globe", title: tr("Übersetzungssprache", "Translation language")) {
                Picker("", selection: Binding(get: { store.language }, set: { store.language = $0 })) {
                    ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
                }.labelsHidden()
            }
            Divider().padding(.leading, 52)
            if purchases.isPremium {
                linkRow(icon: "crown.fill", title: tr("Abo verwalten", "Manage subscription")) { showManage = true }
            } else {
                linkRow(icon: "crown.fill", title: tr("Premium freischalten", "Unlock Premium")) { router.showPaywall("settings") }
            }
            Divider().padding(.leading, 52)
            linkRow(icon: "arrow.clockwise", title: tr("Käufe wiederherstellen", "Restore purchases")) {
                Task { await purchases.restore() }
            }
            Divider().padding(.leading, 52)
            linkRow(icon: "star.fill", title: tr("App bewerten", "Rate the app")) { UIApplication.shared.open(AppLinks.review) }
            Divider().padding(.leading, 52)
            ShareLink(item: AppLinks.appStore, message: Text(tr("Lerne Schwiizerdüütsch mit dieser App 🇨🇭", "Learn Swiss German with this app 🇨🇭"))) {
                rowLabel(icon: "square.and.arrow.up", title: tr("App teilen", "Share the app"))
            }
            Divider().padding(.leading, 52)
            linkRow(icon: "questionmark.circle.fill", title: tr("Hilfe & Feedback", "Help & feedback")) { UIApplication.shared.open(AppLinks.support) }
            Divider().padding(.leading, 52)
            linkRow(icon: "hand.raised.fill", title: tr("Datenschutz", "Privacy Policy")) { UIApplication.shared.open(AppLinks.privacy) }
            Divider().padding(.leading, 52)
            linkRow(icon: "doc.text.fill", title: tr("Nutzungsbedingungen", "Terms of Use")) { UIApplication.shared.open(AppLinks.terms) }
        }
        .card(padding: 4)
        .alert(tr("Hinweis", "Note"), isPresented: Binding(get: { purchases.errorMessage != nil }, set: { if !$0 { purchases.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(purchases.errorMessage ?? "") }
    }

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

    private func rowLabel(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 24)
            Text(title).font(.rounded(.body, .medium)).foregroundStyle(Theme.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 14).padding(.vertical, 14).contentShape(Rectangle())
    }

    private func linkRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) { rowLabel(icon: icon, title: title) }.buttonStyle(.plain)
    }

    private func settingRow<C: View>(icon: String, title: String, @ViewBuilder trailing: () -> C) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 24)
            Text(title).font(.rounded(.body, .medium)).foregroundStyle(Theme.ink)
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

import SwiftUI
import StoreKit

struct PlanInfo: Identifiable {
    let id: String
    let title: String
    let detail: String
    let badge: String?
    let trialDays: Int?
}

struct PaywallView: View {
    let reason: String
    @EnvironmentObject var purchases: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedID = PurchaseManager.yearlyID
    @State private var celebrate = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    hero
                    benefits
                    plans
                    Color.clear.frame(height: 200)
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
            }
            .scrollIndicators(.hidden)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 36, height: 36)
                        .background(Theme.card, in: Circle())
                        .overlay(Circle().stroke(Theme.line, lineWidth: 1.5))
                }
                .accessibilityLabel(tr("Schliessen", "Close"))
                Spacer()
                Button(tr("Wiederherstellen", "Restore")) { Task { await purchases.restore() } }
                    .font(.rounded(.subheadline, .bold)).foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 16).padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) { footer }
        .overlay { if celebrate { celebration } }
        .onChange(of: purchases.isPremium) { _, premium in
            guard premium else { return }
            withAnimation { celebrate = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { dismiss() }
        }
        .alert(tr("Hoppla", "Oops"), isPresented: Binding(get: { purchases.errorMessage != nil }, set: { if !$0 { purchases.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(purchases.errorMessage ?? "") }
    }

    // MARK: Header

    private var hero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(LinearGradient(colors: [Color(hex: 0xFF3B47), Color(hex: 0xC8101E)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                    .shadow(color: Theme.red.opacity(0.35), radius: 18, y: 8)
                Text("🏔️").font(.system(size: 50))
            }
            Text(tr("Schwiizerdüütsch ohne Limit", "Swiss German without limits"))
                .font(.rounded(size: 30, .heavy)).foregroundStyle(Theme.ink).multilineTextAlignment(.center)
            Text(tr("Schalte alle Kapitel frei und sprich bald wie ein:e Einheimische:r.", "Unlock every chapter and soon talk like a local."))
                .font(.rounded(.body)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefit("books.vertical.fill", trf("Alle %d Kapitel · %d Ausdrücke", "All %d chapters · %d phrases", Curriculum.units.count, Curriculum.allPhrases.count))
            benefit("map.fill", tr("Dialekt-Explorer: Züri, Bärn & Basel", "Dialect explorer: Zürich, Bern & Basel"))
            benefit("bolt.heart.fill", tr("Smarte Wiederholung für deine Fehler", "Smart review for your mistakes"))
            benefit("text.book.closed.fill", tr("Vollständiges Phrasebook mit Favoriten", "Full phrasebook with favourites"))
            benefit("arrow.triangle.2.circlepath", tr("Alle künftigen Updates inklusive", "All future updates included"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(padding: 18)
    }

    private func benefit(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 26)
            Text(text).font(.rounded(.subheadline, .semibold)).foregroundStyle(Theme.ink)
            Spacer(minLength: 0)
        }
    }

    // MARK: Plans

    private var planInfos: [PlanInfo] {
        #if DEBUG
        if purchases.products.isEmpty && ProcessInfo.processInfo.arguments.contains("-mockprices") {
            return [
                PlanInfo(id: PurchaseManager.yearlyID, title: tr("Jahr", "Yearly"),
                         detail: trf("%d Tage gratis, danach %@ / Jahr", "%d days free, then %@ / year", 7, "CHF 29.90") + "\n" + trf("nur %@ pro Monat", "only %@ per month", "CHF 2.49"),
                         badge: trf("SPARE %d%%", "SAVE %d%%", 65), trialDays: 7),
                PlanInfo(id: PurchaseManager.lifetimeID, title: tr("Für immer", "Lifetime"),
                         detail: trf("Einmalig %@ · kein Abo", "One-time %@ · no subscription", "CHF 59.90"), badge: nil, trialDays: nil),
                PlanInfo(id: PurchaseManager.monthlyID, title: tr("Monat", "Monthly"),
                         detail: trf("%@ / Monat", "%@ / month", "CHF 6.90"), badge: nil, trialDays: nil),
            ]
        }
        #endif
        return [purchases.yearly, purchases.lifetime, purchases.monthly].compactMap { $0 }.map { p in
            PlanInfo(id: p.id, title: planTitle(p), detail: planDetail(p),
                     badge: p.id == PurchaseManager.yearlyID ? (savingsBadge() ?? tr("BELIEBT", "MOST POPULAR")) : nil,
                     trialDays: trialDays(p))
        }
    }

    @ViewBuilder private var plans: some View {
        if !planInfos.isEmpty {
            VStack(spacing: 12) { ForEach(planInfos) { planCard($0) } }
        } else if !purchases.didLoad {
            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 30)
        } else {
            VStack(spacing: 12) {
                Text(tr("Die Preise konnten nicht geladen werden.", "Prices couldn't be loaded."))
                    .font(.rounded(.subheadline)).foregroundStyle(Theme.muted)
                Button(tr("Nochmals versuchen", "Try again")) { Task { await purchases.load() } }
                    .font(.rounded(.headline, .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 20)
        }
    }

    private func trialDays(_ p: Product) -> Int? {
        guard purchases.trialEligible, let offer = p.subscription?.introductoryOffer, offer.paymentMode == .freeTrial else { return nil }
        let v = offer.period.value
        switch offer.period.unit {
        case .day: return v
        case .week: return v * 7
        case .month: return v * 30
        case .year: return v * 365
        @unknown default: return nil
        }
    }

    private func planTitle(_ p: Product) -> String {
        switch p.id {
        case PurchaseManager.yearlyID: return tr("Jahr", "Yearly")
        case PurchaseManager.monthlyID: return tr("Monat", "Monthly")
        default: return tr("Für immer", "Lifetime")
        }
    }

    private func planDetail(_ p: Product) -> String {
        switch p.id {
        case PurchaseManager.yearlyID:
            let perMonth = p.priceFormatStyle.format(p.price / 12)
            if let d = trialDays(p) {
                return trf("%d Tage gratis, danach %@ / Jahr", "%d days free, then %@ / year", d, p.displayPrice)
                    + "\n" + trf("nur %@ pro Monat", "only %@ per month", perMonth)
            }
            return trf("%@ / Jahr", "%@ / year", p.displayPrice) + "\n" + trf("nur %@ pro Monat", "only %@ per month", perMonth)
        case PurchaseManager.monthlyID:
            return trf("%@ / Monat", "%@ / month", p.displayPrice)
        default:
            return trf("Einmalig %@ · kein Abo", "One-time %@ · no subscription", p.displayPrice)
        }
    }

    private func savingsBadge() -> String? {
        guard let y = purchases.yearly, let m = purchases.monthly, m.price > 0 else { return nil }
        let pct = Int(((1 - (y.price / 12) / m.price) * 100 as NSDecimalNumber).doubleValue.rounded())
        return pct > 5 ? trf("SPARE %d%%", "SAVE %d%%", pct) : nil
    }

    private func planCard(_ p: PlanInfo) -> some View {
        let selected = selectedID == p.id
        return Button {
            withAnimation(.spring(response: 0.3)) { selectedID = p.id }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(selected ? Theme.red : Theme.line)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(p.title).font(.rounded(.headline, .heavy)).foregroundStyle(Theme.ink)
                        if let badge = p.badge {
                            Text(badge)
                                .font(.rounded(size: 10, .heavy)).foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(Theme.green, in: Capsule())
                        }
                    }
                    Text(p.detail).font(.rounded(.footnote)).foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(selected ? Theme.red.opacity(0.07) : Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(selected ? Theme.red : Theme.line, lineWidth: selected ? 2.5 : 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Footer

    private var selectedProduct: Product? { purchases.products.first { $0.id == selectedID } }
    private var selectedPlan: PlanInfo? { planInfos.first { $0.id == selectedID } }

    private var ctaText: String {
        guard let p = selectedPlan else { return tr("Weiter", "Continue") }
        if p.id == PurchaseManager.yearlyID, let d = p.trialDays { return trf("%d Tage gratis testen", "Try %d days free", d) }
        if p.id == PurchaseManager.lifetimeID { return tr("Für immer freischalten", "Unlock forever") }
        return tr("Premium freischalten", "Unlock Premium")
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button {
                guard let p = selectedProduct else { return }
                Task { await purchases.purchase(p) }
            } label: {
                ZStack {
                    Text(ctaText).textCase(.uppercase).opacity(purchases.isBusy ? 0 : 1)
                    if purchases.isBusy { ProgressView().tint(.white) }
                }
            }
            .buttonStyle(.chunky(disabled: selectedPlan == nil))
            .disabled(selectedPlan == nil || purchases.isBusy)

            if let p = selectedPlan, p.id == PurchaseManager.yearlyID, p.trialDays != nil {
                Label(tr("Keine Zahlung jetzt · jederzeit kündbar", "No payment now · cancel anytime"), systemImage: "checkmark.shield.fill")
                    .font(.rounded(.footnote, .semibold)).foregroundStyle(Theme.green)
            }
            Text(tr("Abos verlängern sich automatisch, wenn sie nicht mindestens 24 Stunden vor Ablauf in den Apple-ID-Einstellungen gekündigt werden. Die Zahlung erfolgt über deine Apple-ID.",
                    "Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period in your Apple ID settings. Payment is charged to your Apple ID."))
                .font(.rounded(size: 10)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
            HStack(spacing: 18) {
                Link(tr("Nutzungsbedingungen", "Terms of Use"), destination: AppLinks.terms)
                Link(tr("Datenschutz", "Privacy Policy"), destination: AppLinks.privacy)
            }
            .font(.rounded(.caption, .semibold)).foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 6)
        .background(.regularMaterial)
    }

    private var celebration: some View {
        ZStack {
            Theme.bg.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("🎉").font(.system(size: 80))
                Text(tr("Willkommen bei Premium!", "Welcome to Premium!")).font(.rounded(.title, .heavy)).foregroundStyle(Theme.ink)
                Text(tr("Alle Kapitel sind freigeschaltet.", "All chapters are unlocked.")).font(.rounded(.body)).foregroundStyle(Theme.muted)
            }
            ConfettiView()
        }
        .transition(.opacity)
    }
}

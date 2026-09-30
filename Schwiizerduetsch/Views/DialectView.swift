import SwiftUI

struct DialectView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @State private var selected = "zh"
    @Namespace private var ns

    private var region: DialectRegion { Dialects.regions.first { $0.id == selected } ?? Dialects.regions[0] }
    private let freeCount = 3

    var body: some View {
        NavigationStack {
            ScreenScaffold(title: tr("Dialekte", "Dialects"), subtitle: tr("Jeder Kanton klingt anders.", "Every canton sounds different.")) {
                segmented

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text(region.emoji).font(.system(size: 34))
                        Text(region.name).font(.display(26, .heavy)).foregroundStyle(Theme.ink)
                    }
                    Text(region.blurb).font(.ui(.subheadline)).foregroundStyle(Theme.muted).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading).card(padding: 20)
                .id(region.id)
                .transition(.opacity)

                ForEach(Array(Dialects.concepts.enumerated()), id: \.element.id) { i, c in
                    conceptCard(c, locked: !purchases.isPremium && i >= freeCount)
                }

                Text(tr("Vereinfachte Übersicht – innerhalb der Regionen gibt es viele Varianten.", "Simplified overview – there are many variants within each region."))
                    .font(.ui(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.center).padding(.top, 4)
            }
            .onAppear { if !store.state.dialectOpened { store.state.dialectOpened = true } }
        }
    }

    private var segmented: some View {
        HStack(spacing: 6) {
            ForEach(Dialects.regions) { r in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { selected = r.id }
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    HStack(spacing: 6) {
                        Text(r.emoji)
                        Text(r.name).font(.ui(.subheadline, .bold))
                    }
                    .foregroundStyle(selected == r.id ? .white : Theme.ink)
                    .frame(maxWidth: .infinity).padding(.vertical, 13)
                    .background {
                        if selected == r.id {
                            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.redGradient)
                                .shadow(color: Theme.red.opacity(0.35), radius: 10, y: 5)
                                .matchedGeometryEffect(id: "seg", in: ns)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background(Theme.soft, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
    }

    private func conceptCard(_ c: DialectConcept, locked: Bool) -> some View {
        Button {
            if locked { router.showPaywall("dialects") }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(c.meaning).eyebrow()
                    Spacer()
                    if locked {
                        Label("PREMIUM", systemImage: "lock.fill").font(.ui(size: 10, .heavy)).tracking(0.8).foregroundStyle(Theme.gold)
                    }
                }
                ForEach(Dialects.regions) { r in
                    HStack(spacing: 10) {
                        Text(r.emoji).frame(width: 26)
                        Text(r.name).font(.ui(.footnote, .semibold)).foregroundStyle(Theme.muted).frame(width: 54, alignment: .leading)
                        Text(c.words[r.id] ?? "–")
                            .font(.display(19, r.id == selected ? .heavy : .medium))
                            .foregroundStyle(r.id == selected ? Theme.red : Theme.ink)
                            .redacted(reason: locked ? .placeholder : [])
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(padding: 18)
        }
        .buttonStyle(OptionPressStyle())
    }
}

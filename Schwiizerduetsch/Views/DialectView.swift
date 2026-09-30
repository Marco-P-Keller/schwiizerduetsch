import SwiftUI

struct DialectView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter
    @State private var selected = "zh"

    private var region: DialectRegion { Dialects.regions.first { $0.id == selected } ?? Dialects.regions[0] }
    private let freeCount = 3

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text(tr("Schwiizerdüütsch ist nicht ein Dialekt – jeder Kanton klingt anders. Vergleiche, wie in den Regionen gesprochen wird.",
                            "Swiss German isn't one dialect – every canton sounds different. Compare how regions speak."))
                        .font(.rounded(.subheadline)).foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 10) {
                        ForEach(Dialects.regions) { r in
                            Button { withAnimation(.spring(response: 0.3)) { selected = r.id } } label: {
                                VStack(spacing: 4) {
                                    Text(r.emoji).font(.title)
                                    Text(r.name).font(.rounded(.subheadline, .heavy))
                                }
                                .foregroundStyle(selected == r.id ? .white : Theme.ink)
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(selected == r.id ? Theme.red : Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(selected == r.id ? Theme.redDeep : Theme.line, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text(region.blurb).font(.rounded(.subheadline)).foregroundStyle(Theme.ink)
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gold.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    ForEach(Array(Dialects.concepts.enumerated()), id: \.element.id) { i, c in
                        let locked = !purchases.isPremium && i >= freeCount
                        conceptCard(c, locked: locked)
                    }

                    Text(tr("Vereinfachte Übersicht – innerhalb der Regionen gibt es viele Varianten.", "Simplified overview – there are many variants within each region."))
                        .font(.rounded(.footnote)).foregroundStyle(Theme.muted).multilineTextAlignment(.center)
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(tr("Dialekt-Explorer", "Dialect explorer"))
            .onAppear { if !store.state.dialectOpened { store.state.dialectOpened = true } }
        }
    }

    private func conceptCard(_ c: DialectConcept, locked: Bool) -> some View {
        Button {
            if locked { router.showPaywall("dialects") }
            else if let w = c.words[selected] { SpeechService.shared.speak(w.components(separatedBy: " / ").first ?? w) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(c.meaning).font(.rounded(.caption, .bold)).textCase(.uppercase).foregroundStyle(Theme.muted)
                    Spacer()
                    if locked { Label("PREMIUM", systemImage: "lock.fill").font(.rounded(size: 10, .heavy)).foregroundStyle(Theme.gold) }
                }
                ForEach(Dialects.regions) { r in
                    HStack {
                        Text(r.emoji)
                        Text(r.name).font(.rounded(.footnote, .semibold)).foregroundStyle(Theme.muted).frame(width: 52, alignment: .leading)
                        Text(c.words[r.id] ?? "–")
                            .font(.rounded(.body, r.id == selected ? .heavy : .medium))
                            .foregroundStyle(r.id == selected ? Theme.red : Theme.ink)
                            .redacted(reason: locked ? .placeholder : [])
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
        .buttonStyle(.plain)
    }
}

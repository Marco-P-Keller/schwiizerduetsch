import SwiftUI

@main
struct SchwiizerduetschApp: App {
    @StateObject private var store = ProgressStore()
    @StateObject private var purchases = PurchaseManager()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(purchases)
                .environmentObject(router)
                .tint(Theme.red)
        }
    }
}

enum AppLinks {
    static let appStoreID = "6817791465"
    static let appStore = URL(string: "https://apps.apple.com/app/id6817791465")!
    static let privacy = URL(string: "https://marco-p-keller.github.io/schwiizerduetsch/privacy.html")!
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://marco-p-keller.github.io/schwiizerduetsch/support.html")!
    static let review = URL(string: "https://apps.apple.com/app/id6817791465?action=write-review")!
}

struct PaywallTrigger: Identifiable {
    let id = UUID()
    let reason: String
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var paywall: PaywallTrigger?
    @Published var selectedTab = 0

    func showPaywall(_ reason: String = "generic") { paywall = PaywallTrigger(reason: reason) }
}

struct RootView: View {
    @EnvironmentObject var store: ProgressStore
    @EnvironmentObject var purchases: PurchaseManager
    @EnvironmentObject var router: AppRouter

    var body: some View {
        Group {
            if store.state.onboardingDone {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .id(store.state.language ?? "system")
        .fullScreenCover(item: $router.paywall) { trigger in
            PaywallView(reason: trigger.reason)
        }
        .onAppear {
            #if DEBUG
            debugRoute()
            #endif
            if store.state.reminderEnabled {
                Task { await NotificationService.scheduleDailyReminders(hour: store.state.reminderHour, minute: store.state.reminderMinute) }
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            HomeView()
                .tabItem { Label(tr("Lernen", "Learn"), systemImage: "book.fill") }
                .tag(0)
            PracticeView()
                .tabItem { Label(tr("Üben", "Practice"), systemImage: "bolt.heart.fill") }
                .tag(1)
            DialectView()
                .tabItem { Label(tr("Dialekt", "Dialects"), systemImage: "map.fill") }
                .tag(2)
            ProfileView()
                .tabItem { Label(tr("Profil", "Profile"), systemImage: "person.crop.circle.fill") }
                .tag(3)
        }
    }
}

#if DEBUG
extension RootView {
    /// Launch arguments for screenshots: `-tab N`, `-paywall`
    func debugRoute() {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let n = Int(args[i + 1]) { router.selectedTab = n }
        if args.contains("-paywall") { DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { router.showPaywall("debug") } }
    }
}
#endif

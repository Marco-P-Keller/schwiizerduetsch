import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let yearlyID = "com.connexa.schweizerdeutsch.premium.yearly"
    static let monthlyID = "com.connexa.schweizerdeutsch.premium.monthly"
    static let lifetimeID = "com.connexa.schweizerdeutsch.premium.lifetime"
    static let allIDs = [yearlyID, monthlyID, lifetimeID]

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium: Bool
    @Published private(set) var trialEligible = false
    @Published private(set) var isBusy = false
    @Published private(set) var didLoad = false
    @Published var errorMessage: String?

    private var updates: Task<Void, Never>?
    private let cacheKey = "premium.cached"

    init() {
        isPremium = UserDefaults.standard.bool(forKey: "premium.cached")
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-premium") { isPremium = true }
        #endif
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let t) = result {
                    await t.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        Task { await load() }
    }

    deinit { updates?.cancel() }

    var yearly: Product? { products.first { $0.id == Self.yearlyID } }
    var monthly: Product? { products.first { $0.id == Self.monthlyID } }
    var lifetime: Product? { products.first { $0.id == Self.lifetimeID } }

    func load() async {
        do {
            let loaded = try await Product.products(for: Self.allIDs)
            products = loaded.sorted { $0.price < $1.price }
            if let sub = yearly?.subscription {
                trialEligible = await sub.isEligibleForIntroOffer
            }
        } catch {
            products = []
        }
        didLoad = true
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, Self.allIDs.contains(t.productID), t.revocationDate == nil {
                active = true
            }
        }
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-premium") { active = true }
        #endif
        isPremium = active
        UserDefaults.standard.set(active, forKey: cacheKey)
    }

    /// Returns true when the purchase completed successfully.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isBusy = true
        defer { isBusy = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let t) = verification {
                    await t.finish()
                    await refreshEntitlements()
                    if product.id == Self.yearlyID, trialEligible { await NotificationService.scheduleTrialReminder() }
                    return true
                }
                errorMessage = tr("Der Kauf konnte nicht verifiziert werden.", "The purchase could not be verified.")
            case .pending:
                errorMessage = tr("Der Kauf wartet auf Freigabe.", "The purchase is pending approval.")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        return false
    }

    func restore() async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPremium {
                errorMessage = tr("Keine früheren Käufe gefunden.", "No previous purchases found.")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

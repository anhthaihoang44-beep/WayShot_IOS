import Foundation
import StoreKit

/// Product identifiers for WayShot Pro Tier (ADR-007)
public enum ProProduct: String, CaseIterable, Identifiable {
    case yearly = "com.wayshot.pro.yearly"
    case lifetime = "com.wayshot.pro.lifetime"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .yearly: return "WayShot Pro (Yearly)"
        case .lifetime: return "WayShot Pro (Lifetime)"
        }
    }

    public var priceDescription: String {
        switch self {
        case .yearly: return "$19.99 / year (7-day free trial)"
        case .lifetime: return "$39.99 one-time payment"
        }
    }
}

/// Service managing user subscription and In-App Purchases using StoreKit 2
@MainActor
public final class ProSubscriptionManager: ObservableObject {

    public static let shared = ProSubscriptionManager()

    @Published public private(set) var isPro: Bool = false
    @Published public private(set) var availableProducts: [Product] = []
    @Published public private(set) var isPurchasing: Bool = false
    @Published public private(set) var purchaseErrorMessage: String? = nil

    private var transactionListenerTask: Task<Void, Never>? = nil

    public init() {
        startTransactionListener()
        Task {
            await refreshSubscriptionStatus()
            await loadProducts()
        }
    }

    deinit {
        transactionListenerTask?.cancel()
    }

    /// Listens for background transactions (renewals, family sharing, external purchases)
    private func startTransactionListener() {
        transactionListenerTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.refreshSubscriptionStatus()
                    await transaction?.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    /// Fetches products from Apple App Store
    public func loadProducts() async {
        do {
            let productIds = ProProduct.allCases.map { $0.rawValue }
            let products = try await Product.products(for: Set(productIds))
            self.availableProducts = products
        } catch {
            print("Failed to load StoreKit products: \(error)")
        }
    }

    /// Checks active entitlements for the current user
    public func refreshSubscriptionStatus() async {
        var hasActiveEntitlement = false

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if ProProduct.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    if transaction.revocationDate == nil {
                        hasActiveEntitlement = true
                        break
                    }
                }
            } catch {
                print("Failed to verify entitlement: \(error)")
            }
        }

        self.isPro = hasActiveEntitlement
    }

    /// Initiates a purchase flow for a specified product
    public func purchase(product: Product) async throws -> Bool {
        isPurchasing = true
        purchaseErrorMessage = nil
        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await refreshSubscriptionStatus()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            purchaseErrorMessage = "Purchase is pending approval."
            return false

        @unknown default:
            return false
        }
    }

    /// Restores previous purchases
    public func restorePurchases() async throws {
        isPurchasing = true
        purchaseErrorMessage = nil
        defer { isPurchasing = false }

        try await AppStore.sync()
        await refreshSubscriptionStatus()
    }

    /// Helper to verify StoreKit JWS cryptographic signature
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }

    /// Debug override for testing Pro tier without actual payment
    public func setDebugProStatus(_ status: Bool) {
        self.isPro = status
    }
}

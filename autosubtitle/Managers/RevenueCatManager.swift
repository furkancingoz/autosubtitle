//
//  RevenueCatManager.swift
//  AutoSubtitle
//
//  Manages in-app purchases and subscriptions via RevenueCat
//

import Foundation
import RevenueCat
import Combine

class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()

    @Published var offerings: Offerings?
    @Published var customerInfo: CustomerInfo?
    @Published var isLoading = false
    @Published var error: PurchaseError?

    private let creditManager = CreditManager.shared
    private let userManager = UserManager.shared

    private init() {}

    // MARK: - Setup

    func configure(apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        print("✅ RevenueCat configured")

        // Set user ID when Firebase auth completes
        if let userId = FirebaseAuthManager.shared.userId {
            setUserId(userId)
        }

        Task {
            await fetchOfferings()
            await fetchCustomerInfo()
        }
    }

    func setUserId(_ userId: String) {
        Purchases.shared.logIn(userId) { customerInfo, created, error in
            if let error = error {
                print("❌ RevenueCat login error: \(error.localizedDescription)")
            } else {
                print("✅ RevenueCat user set: \(userId) (created: \(created))")
            }
        }
    }

    // MARK: - Fetch Offerings

    func fetchOfferings() async {
        DispatchQueue.main.async {
            self.isLoading = true
        }

        do {
            let offerings = try await Purchases.shared.offerings()
            DispatchQueue.main.async {
                self.offerings = offerings
                self.isLoading = false
            }
            print("✅ Offerings fetched: \(offerings.all.count)")
        } catch {
            DispatchQueue.main.async {
                self.error = .fetchFailed(error.localizedDescription)
                self.isLoading = false
            }
            print("❌ Failed to fetch offerings: \(error.localizedDescription)")
        }
    }

    func fetchCustomerInfo() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            DispatchQueue.main.async {
                self.customerInfo = customerInfo
            }
            await processCustomerInfo(customerInfo)
        } catch {
            print("❌ Failed to fetch customer info: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            DispatchQueue.main.async {
                self.customerInfo = result.customerInfo
                self.isLoading = false
            }

            await processCustomerInfo(result.customerInfo)
            print("✅ Purchase successful")

        } catch let error as RevenueCat.ErrorCode {
            DispatchQueue.main.async {
                self.isLoading = false
            }

            switch error {
            case .purchaseCancelledError:
                print("ℹ️ Purchase cancelled by user")
                throw PurchaseError.cancelled

            case .paymentPendingError:
                print("⏳ Payment pending")
                throw PurchaseError.pending

            case .productAlreadyPurchasedError:
                print("ℹ️ Product already purchased")
                throw PurchaseError.alreadyPurchased

            default:
                print("❌ Purchase error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.error = .purchaseFailed(error.localizedDescription)
                }
                throw PurchaseError.purchaseFailed(error.localizedDescription)
            }
        } catch {
            DispatchQueue.main.async {
                self.error = .purchaseFailed(error.localizedDescription)
                self.isLoading = false
            }
            throw PurchaseError.purchaseFailed(error.localizedDescription)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async throws {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            DispatchQueue.main.async {
                self.customerInfo = customerInfo
                self.isLoading = false
            }
            await processCustomerInfo(customerInfo)
            print("✅ Purchases restored")
        } catch {
            DispatchQueue.main.async {
                self.error = .restoreFailed(error.localizedDescription)
                self.isLoading = false
            }
            print("❌ Restore failed: \(error.localizedDescription)")
            throw PurchaseError.restoreFailed(error.localizedDescription)
        }
    }

    // MARK: - Process Customer Info

    private func processCustomerInfo(_ customerInfo: CustomerInfo) async {
        // Check active subscriptions
        if let entitlement = customerInfo.entitlements.active.first?.value {
            let productId = entitlement.productIdentifier

            // Map product ID to subscription tier
            var tier: SubscriptionTier = .free

            if productId.contains("starter") {
                tier = .starter
            } else if productId.contains("pro") {
                tier = .pro
            } else if productId.contains("ultimate") {
                tier = .ultimate
            }

            await userManager.updateSubscriptionTier(tier)
            print("✅ Active subscription: \(tier.rawValue)")

            // Grant monthly credits if it's a new billing period
            await handleMonthlyCredits(tier: tier, customerInfo: customerInfo)

        } else {
            // No active subscription
            await userManager.updateSubscriptionTier(.free)
            print("ℹ️ No active subscription")
        }

        // Process one-time purchases (credit packs)
        await processOneTimePurchases(customerInfo)
    }

    private func handleMonthlyCredits(tier: SubscriptionTier, customerInfo: CustomerInfo) async {
        // Check if credits should be granted for this billing period
        // This is a simplified version - in production, you'd track billing periods more carefully

        guard let entitlement = customerInfo.entitlements.active.first?.value else { return }

        let periodType = entitlement.periodType

        // Only grant credits for active subscriptions
        if periodType == .normal {
            let monthlyCredits = tier.monthlyCredits

            // In production, you'd check if credits were already granted this period
            // For now, we'll add a UserDefaults check

            let lastGrantKey = "lastCreditGrant_\(tier.rawValue)"
            let lastGrantDate = UserDefaults.standard.object(forKey: lastGrantKey) as? Date
            let now = Date()

            let shouldGrantCredits: Bool
            if let lastGrant = lastGrantDate {
                // Grant if more than 28 days have passed
                shouldGrantCredits = now.timeIntervalSince(lastGrant) > (28 * 24 * 60 * 60)
            } else {
                shouldGrantCredits = true
            }

            if shouldGrantCredits {
                do {
                    try await creditManager.addCredits(
                        monthlyCredits,
                        type: .subscription,
                        description: "\(tier.displayName) monthly credits"
                    )
                    await userManager.incrementCreditsPurchased(monthlyCredits)
                    UserDefaults.standard.set(now, forKey: lastGrantKey)
                    print("✅ Monthly credits granted: \(monthlyCredits)")
                } catch {
                    print("❌ Failed to grant monthly credits: \(error.localizedDescription)")
                }
            }
        }
    }

    private func processOneTimePurchases(_ customerInfo: CustomerInfo) async {
        // Track which credit packs have been processed
        let processedKey = "processedPurchases"
        var processedPurchases = UserDefaults.standard.stringArray(forKey: processedKey) ?? []

        for purchase in customerInfo.nonSubscriptionTransactions {
            let transactionId = purchase.transactionIdentifier

            // Skip if already processed
            guard !processedPurchases.contains(transactionId) else { continue }

            // Find matching product
            let productId = purchase.productIdentifier
            guard let product = ProductCatalog.getProduct(byId: productId) else { continue }

            // Grant credits
            do {
                try await creditManager.addCredits(
                    product.credits,
                    type: .purchase,
                    reference: transactionId,
                    description: "\(product.name) purchase"
                )
                await userManager.incrementCreditsPurchased(product.credits)

                // Mark as processed
                processedPurchases.append(transactionId)
                UserDefaults.standard.set(processedPurchases, forKey: processedKey)

                print("✅ Credits granted from purchase: \(product.credits)")
            } catch {
                print("❌ Failed to process purchase: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Helper Methods

    var hasActiveSubscription: Bool {
        customerInfo?.entitlements.active.isEmpty == false
    }

    var currentSubscriptionTier: SubscriptionTier {
        guard let entitlement = customerInfo?.entitlements.active.first?.value else {
            return .free
        }

        let productId = entitlement.productIdentifier

        if productId.contains("starter") {
            return .starter
        } else if productId.contains("pro") {
            return .pro
        } else if productId.contains("ultimate") {
            return .ultimate
        }

        return .free
    }

    func checkTrialEligibility(for package: Package) async -> Bool {
        guard customerInfo != nil else { return false }

        // In RevenueCat 4.x, trial eligibility check has changed
        // For simplicity, we'll check if the user has any active entitlements
        // If no active entitlements, they're likely eligible for trial
        guard let info = customerInfo else { return true }

        return info.entitlements.active.isEmpty
    }
}

// MARK: - Error Types

enum PurchaseError: LocalizedError, Identifiable {
    case fetchFailed(String)
    case purchaseFailed(String)
    case restoreFailed(String)
    case cancelled
    case pending
    case alreadyPurchased

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to load products: \(message)"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Failed to restore purchases: \(message)"
        case .cancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .alreadyPurchased:
            return "You already own this product"
        }
    }
}

//
//  CreditManager.swift
//  AutoSubtitle
//
//  Manages user credits with Keychain storage and Firebase sync
//

import Foundation
import Security
import Combine

class CreditManager: ObservableObject {
    static let shared = CreditManager()

    @Published var creditBalance: Int = 0
    @Published var isLoading = false
    @Published var error: CreditError?

    private let keychainService = "com.autosubtitle.credits"
    private let userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        loadCreditsFromKeychain()
        observeUserChanges()
    }

    // MARK: - Keychain Operations

    private func loadCreditsFromKeychain() {
        guard let userId = FirebaseAuthManager.shared.userId else {
            print("⚠️ No user ID available, cannot load credits")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let credits = try? JSONDecoder().decode(Int.self, from: data) {
            DispatchQueue.main.async {
                self.creditBalance = credits
            }
            print("✅ Credits loaded from Keychain: \(credits)")
        } else if status == errSecItemNotFound {
            print("ℹ️ No credits found in Keychain, will sync from Firebase")
            Task {
                await syncCreditsFromFirebase()
            }
        } else {
            print("❌ Keychain read error: \(status)")
        }
    }

    private func saveCreditsToKeychain(_ credits: Int) {
        guard let userId = FirebaseAuthManager.shared.userId else {
            print("⚠️ No user ID available, cannot save credits")
            return
        }

        guard let data = try? JSONEncoder().encode(credits) else {
            print("❌ Failed to encode credits")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userId
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        // Try to update first
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, create it
            var addQuery = query
            addQuery[kSecValueData as String] = data
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)

            if addStatus == errSecSuccess {
                print("✅ Credits saved to Keychain: \(credits)")
            } else {
                print("❌ Keychain add error: \(addStatus)")
            }
        } else if updateStatus == errSecSuccess {
            print("✅ Credits updated in Keychain: \(credits)")
        } else {
            print("❌ Keychain update error: \(updateStatus)")
        }
    }

    private func deleteCreditsFromKeychain() {
        guard let userId = FirebaseAuthManager.shared.userId else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: userId
        ]

        SecItemDelete(query as CFDictionary)
        print("🗑️ Credits deleted from Keychain")
    }

    // MARK: - Firebase Sync

    func syncCreditsFromFirebase() async {
        guard let user = try? await userManager.getCurrentUser() else {
            print("⚠️ Cannot sync credits: no user")
            return
        }

        DispatchQueue.main.async {
            self.creditBalance = user.creditBalance
            self.saveCreditsToKeychain(user.creditBalance)
        }
        print("🔄 Credits synced from Firebase: \(user.creditBalance)")
    }

    private func syncCreditsToFirebase(_ credits: Int) async {
        await userManager.updateCreditBalance(credits)
    }

    // MARK: - Credit Operations

    func addCredits(_ amount: Int, type: TransactionType, reference: String? = nil, description: String? = nil) async throws {
        guard amount > 0 else {
            throw CreditError.invalidAmount
        }

        let newBalance = creditBalance + amount

        // Update local storage
        DispatchQueue.main.async {
            self.creditBalance = newBalance
            self.saveCreditsToKeychain(newBalance)
        }

        // Sync to Firebase
        await syncCreditsToFirebase(newBalance)

        // Record transaction
        try await recordTransaction(
            amount: amount,
            type: type,
            reference: reference,
            balanceAfter: newBalance,
            description: description
        )

        print("✅ Credits added: +\(amount) → Balance: \(newBalance)")
    }

    func deductCredits(_ amount: Int, type: TransactionType = .deduction, reference: String? = nil, description: String? = nil) async throws {
        guard amount > 0 else {
            throw CreditError.invalidAmount
        }

        guard creditBalance >= amount else {
            throw CreditError.insufficientCredits
        }

        let newBalance = creditBalance - amount

        // Update local storage
        DispatchQueue.main.async {
            self.creditBalance = newBalance
            self.saveCreditsToKeychain(newBalance)
        }

        // Sync to Firebase
        await syncCreditsToFirebase(newBalance)

        // Record transaction
        try await recordTransaction(
            amount: -amount,
            type: type,
            reference: reference,
            balanceAfter: newBalance,
            description: description
        )

        print("✅ Credits deducted: -\(amount) → Balance: \(newBalance)")
    }

    func refundCredits(_ amount: Int, reference: String? = nil, description: String? = nil) async throws {
        guard amount > 0 else {
            throw CreditError.invalidAmount
        }

        let newBalance = creditBalance + amount

        // Update local storage
        DispatchQueue.main.async {
            self.creditBalance = newBalance
            self.saveCreditsToKeychain(newBalance)
        }

        // Sync to Firebase
        await syncCreditsToFirebase(newBalance)

        // Record transaction
        try await recordTransaction(
            amount: amount,
            type: .refund,
            reference: reference,
            balanceAfter: newBalance,
            description: description
        )

        print("💰 Credits refunded: +\(amount) → Balance: \(newBalance)")
    }

    // MARK: - Transaction History

    private func recordTransaction(
        amount: Int,
        type: TransactionType,
        reference: String?,
        balanceAfter: Int,
        description: String?
    ) async throws {
        guard let userId = FirebaseAuthManager.shared.userId else {
            throw CreditError.noUser
        }

        let transaction = CreditTransaction(
            userId: userId,
            amount: amount,
            type: type,
            reference: reference,
            timestamp: Date(),
            balanceAfter: balanceAfter,
            description: description
        )

        try await userManager.recordTransaction(transaction)
    }

    // MARK: - Validation

    func hasEnoughCredits(for duration: TimeInterval) -> Bool {
        let requiredCredits = calculateRequiredCredits(for: duration)
        return creditBalance >= requiredCredits
    }

    func calculateRequiredCredits(for duration: TimeInterval) -> Int {
        let minutes = ceil(duration / 60.0)
        return max(1, Int(minutes))
    }

    // MARK: - User Observation

    private func observeUserChanges() {
        userManager.$currentUser
            .compactMap { $0 }
            .sink { [weak self] user in
                // Update credits if Firebase has different value
                if user.creditBalance != self?.creditBalance {
                    DispatchQueue.main.async {
                        self?.creditBalance = user.creditBalance
                        self?.saveCreditsToKeychain(user.creditBalance)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Reset

    func reset() {
        creditBalance = 0
        deleteCreditsFromKeychain()
        print("🔄 Credits reset")
    }
}

// MARK: - Error Types

enum CreditError: LocalizedError, Identifiable {
    case insufficientCredits
    case invalidAmount
    case syncFailed
    case noUser

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .insufficientCredits:
            return "You don't have enough credits for this operation"
        case .invalidAmount:
            return "Invalid credit amount"
        case .syncFailed:
            return "Failed to sync credits with server"
        case .noUser:
            return "No user is currently signed in"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .insufficientCredits:
            return "Purchase more credits or upgrade your subscription"
        case .syncFailed:
            return "Please check your internet connection and try again"
        default:
            return nil
        }
    }
}

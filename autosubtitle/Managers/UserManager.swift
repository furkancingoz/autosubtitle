//
//  UserManager.swift
//  AutoSubtitle
//
//  Manages user data with Firebase Firestore
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

class UserManager: ObservableObject {
    static let shared = UserManager()

    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: UserError?

    private let db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private let authManager = FirebaseAuthManager.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        observeAuthChanges()
    }

    deinit {
        userListener?.remove()
    }

    // MARK: - Auth Observation

    private func observeAuthChanges() {
        authManager.$currentUser
            .sink { [weak self] firebaseUser in
                if let userId = firebaseUser?.uid {
                    Task {
                        await self?.setupUserListener(userId: userId)
                    }
                } else {
                    self?.userListener?.remove()
                    DispatchQueue.main.async {
                        self?.currentUser = nil
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - User Creation & Fetching

    func createOrFetchUser() async throws -> User {
        guard let firebaseUID = authManager.userId else {
            throw UserError.notAuthenticated
        }

        // Try to fetch existing user
        if let existingUser = try? await fetchUser(userId: firebaseUID) {
            DispatchQueue.main.async {
                self.currentUser = existingUser
            }
            return existingUser
        }

        // Create new user
        let newUser = User(firebaseUID: firebaseUID)

        try await db.collection("users").document(firebaseUID).setData([
            "firebaseUID": newUser.firebaseUID,
            "creditBalance": newUser.creditBalance,
            "subscriptionTier": newUser.subscriptionTier.rawValue,
            "createdAt": Timestamp(date: newUser.createdAt),
            "lastActive": Timestamp(date: newUser.lastActive),
            "totalVideosProcessed": newUser.totalVideosProcessed,
            "totalCreditsUsed": newUser.totalCreditsUsed,
            "totalCreditsPurchased": newUser.totalCreditsPurchased
        ])

        DispatchQueue.main.async {
            self.currentUser = newUser
        }

        print("✅ New user created: \(firebaseUID)")
        return newUser
    }

    private func fetchUser(userId: String) async throws -> User {
        let document = try await db.collection("users").document(userId).getDocument()

        guard document.exists else {
            throw UserError.userNotFound
        }

        let user = try document.data(as: User.self)
        return user
    }

    func getCurrentUser() async throws -> User {
        if let user = currentUser {
            return user
        }

        return try await createOrFetchUser()
    }

    // MARK: - Real-time Listener

    private func setupUserListener(userId: String) async {
        userListener?.remove()

        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ User listener error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.error = .fetchFailed(error.localizedDescription)
                    }
                    return
                }

                guard let snapshot = snapshot, snapshot.exists else {
                    print("⚠️ User document doesn't exist")
                    return
                }

                do {
                    let user = try snapshot.data(as: User.self)
                    DispatchQueue.main.async {
                        self?.currentUser = user
                    }
                    print("🔄 User data updated")
                } catch {
                    print("❌ Failed to decode user: \(error.localizedDescription)")
                }
            }
    }

    // MARK: - User Updates

    func updateCreditBalance(_ newBalance: Int) async {
        guard let userId = authManager.userId else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "creditBalance": newBalance,
                "lastActive": Timestamp(date: Date())
            ])
            print("✅ Credit balance updated in Firebase: \(newBalance)")
        } catch {
            print("❌ Failed to update credit balance: \(error.localizedDescription)")
        }
    }

    func updateSubscriptionTier(_ tier: SubscriptionTier) async {
        guard let userId = authManager.userId else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "subscriptionTier": tier.rawValue,
                "lastActive": Timestamp(date: Date())
            ])
            print("✅ Subscription tier updated: \(tier.rawValue)")
        } catch {
            print("❌ Failed to update subscription tier: \(error.localizedDescription)")
        }
    }

    func incrementVideosProcessed() async {
        guard let userId = authManager.userId else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "totalVideosProcessed": FieldValue.increment(Int64(1)),
                "lastActive": Timestamp(date: Date())
            ])
            print("✅ Videos processed count incremented")
        } catch {
            print("❌ Failed to increment videos processed: \(error.localizedDescription)")
        }
    }

    func incrementCreditsUsed(_ amount: Int) async {
        guard let userId = authManager.userId else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "totalCreditsUsed": FieldValue.increment(Int64(amount)),
                "lastActive": Timestamp(date: Date())
            ])
        } catch {
            print("❌ Failed to increment credits used: \(error.localizedDescription)")
        }
    }

    func incrementCreditsPurchased(_ amount: Int) async {
        guard let userId = authManager.userId else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "totalCreditsPurchased": FieldValue.increment(Int64(amount)),
                "lastActive": Timestamp(date: Date())
            ])
        } catch {
            print("❌ Failed to increment credits purchased: \(error.localizedDescription)")
        }
    }

    func updateLastActive() async {
        guard let userId = authManager.userId else { return }

        do {
            try await db.collection("users").document(userId).updateData([
                "lastActive": Timestamp(date: Date())
            ])
        } catch {
            print("❌ Failed to update last active: \(error.localizedDescription)")
        }
    }

    // MARK: - Transaction History

    func recordTransaction(_ transaction: CreditTransaction) async throws {
        guard let userId = authManager.userId else {
            throw UserError.notAuthenticated
        }

        var transactionData = transaction
        transactionData.userId = userId

        try db.collection("users")
            .document(userId)
            .collection("transactions")
            .addDocument(from: transactionData)

        print("✅ Transaction recorded: \(transaction.type.rawValue) \(transaction.amount)")
    }

    func fetchTransactions(limit: Int = 50) async throws -> [CreditTransaction] {
        guard let userId = authManager.userId else {
            throw UserError.notAuthenticated
        }

        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("transactions")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.compactMap { document in
            try document.data(as: CreditTransaction.self)
        }
    }

    // MARK: - Delete User

    func deleteUserData() async throws {
        guard let userId = authManager.userId else {
            throw UserError.notAuthenticated
        }

        // Delete user document
        try await db.collection("users").document(userId).delete()

        // Note: In production, you should also delete subcollections
        // This requires a Cloud Function or batch operations

        DispatchQueue.main.async {
            self.currentUser = nil
        }

        print("✅ User data deleted")
    }
}

// MARK: - Error Types

enum UserError: LocalizedError, Identifiable {
    case notAuthenticated
    case userNotFound
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .userNotFound:
            return "User not found"
        case .fetchFailed(let message):
            return "Failed to fetch user data: \(message)"
        case .updateFailed(let message):
            return "Failed to update user data: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete user data: \(message)"
        }
    }
}

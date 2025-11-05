//
//  FirebaseAuthManager.swift
//  AutoSubtitle
//
//  Manages Firebase anonymous authentication
//

import Foundation
import FirebaseAuth
import Combine

class FirebaseAuthManager: ObservableObject {
    static let shared = FirebaseAuthManager()

    @Published var currentUser: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AuthError?

    private var authStateHandler: AuthStateDidChangeListenerHandle?

    private init() {
        setupAuthStateListener()
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    // MARK: - Setup

    private func setupAuthStateListener() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                print("📱 Auth state changed: \(user?.uid ?? "nil")")
            }
        }
    }

    // MARK: - Sign In

    func signInAnonymously() async throws {
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }

        do {
            let result = try await Auth.auth().signInAnonymously()
            DispatchQueue.main.async {
                self.currentUser = result.user
                self.isAuthenticated = true
                self.isLoading = false
            }
            print("✅ Anonymous sign-in successful: \(result.user.uid)")
        } catch {
            DispatchQueue.main.async {
                self.error = .signInFailed(error.localizedDescription)
                self.isLoading = false
            }
            print("❌ Anonymous sign-in failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            print("✅ Sign out successful")
        } catch {
            DispatchQueue.main.async {
                self.error = .signOutFailed(error.localizedDescription)
            }
            print("❌ Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.noUser
        }

        do {
            try await user.delete()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
            print("✅ Account deleted successfully")
        } catch {
            DispatchQueue.main.async {
                self.error = .deleteFailed(error.localizedDescription)
            }
            print("❌ Account deletion failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Token Management

    func getCurrentUserToken() async throws -> String {
        guard let user = currentUser else {
            throw AuthError.noUser
        }

        do {
            let token = try await user.getIDToken()
            return token
        } catch {
            print("❌ Failed to get user token: \(error.localizedDescription)")
            throw AuthError.tokenFetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Auto Sign-In

    func autoSignInIfNeeded() async {
        if currentUser == nil {
            do {
                try await signInAnonymously()
            } catch {
                print("❌ Auto sign-in failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - User ID

    var userId: String? {
        currentUser?.uid
    }
}

// MARK: - Error Types

enum AuthError: LocalizedError, Identifiable {
    case signInFailed(String)
    case signOutFailed(String)
    case deleteFailed(String)
    case tokenFetchFailed(String)
    case noUser

    var id: String {
        errorDescription ?? "unknown"
    }

    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign-in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign-out failed: \(message)"
        case .deleteFailed(let message):
            return "Account deletion failed: \(message)"
        case .tokenFetchFailed(let message):
            return "Token fetch failed: \(message)"
        case .noUser:
            return "No user is currently signed in"
        }
    }
}

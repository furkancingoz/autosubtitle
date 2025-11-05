//
//  AutoSubtitleApp.swift
//  AutoSubtitle
//
//  Main app entry point
//

import SwiftUI
import Firebase
import RevenueCat

@main
struct AutoSubtitleApp: App {
    @StateObject private var authManager = FirebaseAuthManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var creditManager = CreditManager.shared
    @StateObject private var revenueCatManager = RevenueCatManager.shared
    @StateObject private var videoProcessor = VideoProcessor.shared
    @StateObject private var remoteConfigManager = RemoteConfigManager.shared

    @State private var isInitializing = true
    @State private var initializationError: String?

    init() {
        // Configure Firebase
        FirebaseApp.configure()
        print("✅ Firebase configured")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isInitializing {
                    InitializationView(error: initializationError)
                } else {
                    RootView()
                        .environmentObject(authManager)
                        .environmentObject(userManager)
                        .environmentObject(creditManager)
                        .environmentObject(revenueCatManager)
                        .environmentObject(videoProcessor)
                        .environmentObject(remoteConfigManager)
                }
            }
            .task {
                await initializeApp()
            }
        }
    }

    // MARK: - App Initialization

    private func initializeApp() async {
        do {
            print("🚀 Starting app initialization...")

            // Step 1: Fetch Remote Config
            print("📡 Fetching Remote Config...")
            try await remoteConfigManager.fetchConfigWithTimeout(timeout: 10)

            // Step 2: Validate Configuration
            print("✅ Validating configuration...")
            guard remoteConfigManager.validateConfiguration() else {
                throw InitializationError.invalidConfiguration
            }

            // Step 3: Configure RevenueCat
            let revenueCatKey = remoteConfigManager.revenueCatAPIKey
            if !revenueCatKey.isEmpty {
                print("💰 Configuring RevenueCat...")
                Purchases.logLevel = .debug
                Purchases.configure(withAPIKey: revenueCatKey)
                revenueCatManager.configure(apiKey: revenueCatKey)
            } else {
                print("⚠️ RevenueCat API key not available, skipping configuration")
            }

            // Step 4: Configure FalAI Service
            let falKey = remoteConfigManager.falAPIKey
            if !falKey.isEmpty {
                print("🎬 Configuring fal.ai service...")
                FalAIService.shared.setAPIKey(falKey)
            } else {
                print("⚠️ fal.ai API key not available, skipping configuration")
            }

            // Step 5: Auto sign-in
            print("🔐 Attempting auto sign-in...")
            await authManager.autoSignInIfNeeded()

            // Step 6: Load user data
            if authManager.isAuthenticated {
                print("👤 Loading user data...")
                _ = try? await userManager.createOrFetchUser()
                await creditManager.syncCreditsFromFirebase()
            }

            // Step 7: Complete initialization
            print("✅ App initialization complete!")
            await MainActor.run {
                isInitializing = false
            }

        } catch {
            print("❌ App initialization failed: \(error.localizedDescription)")
            await MainActor.run {
                initializationError = error.localizedDescription

                // Still allow app to continue with limited functionality
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    isInitializing = false
                }
            }
        }
    }
}

// MARK: - Initialization View

struct InitializationView: View {
    let error: String?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Logo or app name
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("AutoSubtitle")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)

                if let error = error {
                    // Error state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.yellow)

                        Text("Initialization Warning")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Text("Starting with limited features...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 8)
                    }
                } else {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)

                        Text("Initializing...")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Loading configuration...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var remoteConfigManager: RemoteConfigManager

    var body: some View {
        Group {
            if authManager.isLoading {
                LoadingView()
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .alert("Configuration Error", isPresented: .constant(remoteConfigManager.error != nil)) {
            Button("OK") {
                remoteConfigManager.error = nil
            }
        } message: {
            if let error = remoteConfigManager.error {
                Text(error.localizedDescription)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.purple)

                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Errors

enum InitializationError: LocalizedError {
    case invalidConfiguration

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid configuration. Please check Remote Config settings."
        }
    }
}

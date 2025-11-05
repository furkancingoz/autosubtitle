//
//  SettingsView.swift
//  AutoSubtitle
//
//  App settings and account management
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager

    @State private var showDeleteAlert = false
    @State private var showSignOutAlert = false
    @State private var showRestoreAlert = false

    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    if let user = userManager.currentUser {
                        accountInfoRow(user: user)
                    }

                    if revenueCatManager.hasActiveSubscription {
                        subscriptionRow
                    }

                    Button("Restore Purchases") {
                        showRestoreAlert = true
                    }
                    .foregroundColor(.purple)
                }

                // Statistics Section
                Section("Statistics") {
                    if let user = userManager.currentUser {
                        statisticsRows(user: user)
                    }
                }

                // Support Section
                Section("Support") {
                    Link(destination: URL(string: "mailto:support@autosubtitle.app")!) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://autosubtitle.app/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://autosubtitle.app/terms")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // App Info Section
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                }

                // Danger Zone
                Section {
                    Button("Sign Out", role: .destructive) {
                        showSignOutAlert = true
                    }

                    Button("Delete Account", role: .destructive) {
                        showDeleteAlert = true
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("Deleting your account will permanently remove all your data including credits, transaction history, and processed videos. This action cannot be undone.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Restore") {
                    restorePurchases()
                }
            } message: {
                Text("This will restore any previous purchases made with this Apple ID.")
            }
        }
    }

    // MARK: - Components

    private func accountInfoRow(user: User) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Account")
                        .font(.headline)

                    Text(user.firebaseUID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            HStack {
                Label("\(user.creditBalance)", systemImage: "dollarsign.circle.fill")
                    .foregroundColor(.purple)

                Spacer()

                Label(user.subscriptionTier.displayName, systemImage: user.isSubscribed ? "crown.fill" : "")
                    .foregroundColor(user.isSubscribed ? .orange : .secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }

    private var subscriptionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Subscription")
                    .font(.subheadline)

                Text(revenueCatManager.currentSubscriptionTier.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "crown.fill")
                .foregroundColor(.orange)
        }
    }

    private func statisticsRows(user: User) -> some View {
        Group {
            HStack {
                Text("Videos Processed")
                Spacer()
                Text("\(user.totalVideosProcessed)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Credits Purchased")
                Spacer()
                Text("\(user.totalCreditsPurchased)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Credits Used")
                Spacer()
                Text("\(user.totalCreditsUsed)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Member Since")
                Spacer()
                Text(user.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Actions

    private func signOut() {
        do {
            try authManager.signOut()
            creditManager.reset()
        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")
        }
    }

    private func deleteAccount() {
        Task {
            do {
                // Delete user data from Firebase
                try await userManager.deleteUserData()

                // Delete Firebase account
                try await authManager.deleteAccount()

                // Clear local data
                creditManager.reset()

                print("✅ Account deleted successfully")
            } catch {
                print("❌ Account deletion failed: \(error.localizedDescription)")
            }
        }
    }

    private func restorePurchases() {
        Task {
            do {
                try await revenueCatManager.restorePurchases()
            } catch {
                print("❌ Restore failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(FirebaseAuthManager.shared)
        .environmentObject(UserManager.shared)
        .environmentObject(CreditManager.shared)
        .environmentObject(RevenueCatManager.shared)
}

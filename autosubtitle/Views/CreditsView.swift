//
//  CreditsView.swift
//  AutoSubtitle
//
//  Credits balance and transaction history
//

import SwiftUI

struct CreditsView: View {
    @EnvironmentObject var creditManager: CreditManager
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager

    @State private var transactions: [CreditTransaction] = []
    @State private var isLoadingTransactions = false
    @State private var showPaywall = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Card
                    balanceCard

                    // Subscription Status
                    if revenueCatManager.hasActiveSubscription {
                        subscriptionStatusCard
                    }

                    // Quick Actions
                    quickActionsSection

                    // Transaction History
                    transactionHistorySection
                }
                .padding()
            }
            .navigationTitle("Credits")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                await loadTransactions()
            }
            .refreshable {
                await loadTransactions()
            }
        }
    }

    // MARK: - Components

    private var balanceCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            VStack(spacing: 4) {
                Text("Available Credits")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("\(creditManager.creditBalance)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.purple)
            }

            if let user = userManager.currentUser {
                VStack(spacing: 4) {
                    HStack {
                        Text("Total Purchased:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(user.totalCreditsPurchased)")
                            .bold()
                    }
                    .font(.caption)

                    HStack {
                        Text("Total Used:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(user.totalCreditsUsed)")
                            .bold()
                    }
                    .font(.caption)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }

    private var subscriptionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.orange)

                Text(revenueCatManager.currentSubscriptionTier.displayName)
                    .font(.headline)

                Spacer()

                Text("Active")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(12)
            }

            Text("\(revenueCatManager.currentSubscriptionTier.monthlyCredits) credits per month")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showPaywall = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)

                    Text("Get More Credits")
                        .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.purple)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }

            if !revenueCatManager.hasActiveSubscription {
                Button(action: { showPaywall = true }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.title2)

                        Text("Upgrade to Pro")
                            .font(.headline)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.orange)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    private var transactionHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction History")
                .font(.headline)
                .padding(.horizontal, 4)

            if isLoadingTransactions {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if transactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("No transactions yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(transactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func loadTransactions() async {
        isLoadingTransactions = true
        do {
            transactions = try await userManager.fetchTransactions(limit: 50)
        } catch {
            print("❌ Failed to load transactions: \(error.localizedDescription)")
        }
        isLoadingTransactions = false
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: CreditTransaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.icon)
                .font(.title3)
                .foregroundColor(transaction.isPositive ? .green : .red)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type.displayName)
                    .font(.subheadline.bold())

                Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let description = transaction.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.displayAmount)
                    .font(.headline)
                    .foregroundColor(transaction.isPositive ? .green : .red)

                Text("Balance: \(transaction.balanceAfter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    CreditsView()
        .environmentObject(CreditManager.shared)
        .environmentObject(UserManager.shared)
        .environmentObject(RevenueCatManager.shared)
}

//
//  PaywallView.swift
//  AutoSubtitle
//
//  Paywall for subscriptions and credit purchases
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @EnvironmentObject var creditManager: CreditManager

    @State private var selectedTab = 0
    @State private var selectedPackage: Package?
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPurchasing = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Tab Selector
                    Picker("Type", selection: $selectedTab) {
                        Text("Subscriptions").tag(0)
                        Text("Credit Packs").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Products
                    if selectedTab == 0 {
                        subscriptionsSection
                    } else {
                        creditPacksSection
                    }

                    // Features List
                    featuresSection

                    // Restore Button
                    Button("Restore Purchases") {
                        restorePurchases()
                    }
                    .font(.subheadline)
                    .foregroundColor(.purple)
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Get Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Components

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text("Unlock More Credits")
                .font(.title.bold())

            Text("Choose a plan that works for you")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Current Balance
            HStack {
                Text("Current Balance:")
                    .foregroundColor(.secondary)
                Text("\(creditManager.creditBalance) credits")
                    .bold()
                    .foregroundColor(.purple)
            }
            .font(.subheadline)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
    }

    private var subscriptionsSection: some View {
        VStack(spacing: 16) {
            ForEach(ProductCatalog.subscriptions) { product in
                SubscriptionCard(
                    product: product,
                    isSelected: false,
                    onSelect: {
                        purchaseProduct(product)
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    private var creditPacksSection: some View {
        VStack(spacing: 16) {
            ForEach(ProductCatalog.oneTimePurchases) { product in
                CreditPackCard(
                    product: product,
                    onSelect: {
                        purchaseProduct(product)
                    }
                )
            }
        }
        .padding(.horizontal)
    }

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What You Get")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                FeatureRow(icon: "checkmark.circle.fill", text: "High-quality AI transcription")
                FeatureRow(icon: "checkmark.circle.fill", text: "Multiple language support")
                FeatureRow(icon: "checkmark.circle.fill", text: "Customizable subtitle styles")
                FeatureRow(icon: "checkmark.circle.fill", text: "Fast processing")
                FeatureRow(icon: "checkmark.circle.fill", text: "No watermarks (paid plans)")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func purchaseProduct(_ product: PurchaseProduct) {
        guard let offerings = revenueCatManager.offerings else {
            errorMessage = "Products not loaded yet. Please try again."
            showError = true
            return
        }

        // Find the RevenueCat package
        let package = offerings.all.values
            .flatMap { $0.availablePackages }
            .first { $0.storeProduct.productIdentifier == product.id }

        guard let package = package else {
            errorMessage = "Product not found"
            showError = true
            return
        }

        isPurchasing = true

        Task {
            do {
                try await revenueCatManager.purchase(package: package)
                dismiss()
            } catch {
                if let purchaseError = error as? PurchaseError {
                    switch purchaseError {
                    case .cancelled:
                        // User cancelled, don't show error
                        break
                    default:
                        errorMessage = purchaseError.localizedDescription
                        showError = true
                    }
                } else {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            isPurchasing = false
        }
    }

    private func restorePurchases() {
        isPurchasing = true

        Task {
            do {
                try await revenueCatManager.restorePurchases()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isPurchasing = false
        }
    }
}

// MARK: - Subscription Card

struct SubscriptionCard: View {
    let product: PurchaseProduct
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with badge
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.title2.bold())

                        Text("\(product.credits) credits/month")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if let badge = product.badge {
                        Text(badge)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                }

                // Price
                HStack(alignment: .firstTextBaseline) {
                    Text(product.price)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.purple)

                    Text("/month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(product.features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)

                            Text(feature)
                                .font(.subheadline)
                        }
                    }
                }

                // CTA
                Text("Subscribe")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .cornerRadius(12)
            }
            .padding()
            .background(
                product.isPopular
                    ? LinearGradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    : LinearGradient(colors: [Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(product.isPopular ? Color.purple : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Credit Pack Card

struct CreditPackCard: View {
    let product: PurchaseProduct
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.headline)

                    Text("\(product.credits) credits")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let savings = product.savings {
                        Text("Save \(savings)")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.price)
                        .font(.title2.bold())
                        .foregroundColor(.purple)

                    Text("$\(String(format: "%.2f", product.pricePerCredit))/credit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(RevenueCatManager.shared)
        .environmentObject(CreditManager.shared)
}

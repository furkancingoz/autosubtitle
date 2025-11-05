//
//  PurchaseProduct.swift
//  AutoSubtitle
//
//  Models for in-app purchases and subscriptions
//

import Foundation

struct PurchaseProduct: Identifiable {
    let id: String // RevenueCat product identifier
    let name: String
    let type: ProductType
    let credits: Int
    let price: String
    let pricePerCredit: Double
    let features: [String]
    let isPopular: Bool
    let savings: String?

    var displayPrice: String {
        switch type {
        case .subscription:
            return "\(price)/month"
        case .oneTime:
            return price
        }
    }

    var badge: String? {
        if isPopular {
            return "MOST POPULAR"
        }
        if let savings = savings {
            return "SAVE \(savings)"
        }
        return nil
    }
}

enum ProductType {
    case subscription
    case oneTime
}

// MARK: - Product Catalog

struct ProductCatalog {

    // MARK: Subscriptions

    static let subscriptions: [PurchaseProduct] = [
        PurchaseProduct(
            id: "com.autosubtitle.subscription.starter.monthly",
            name: "Starter",
            type: .subscription,
            credits: 60,
            price: "$9.99",
            pricePerCredit: 0.166,
            features: [
                "60 videos per month",
                "HD quality",
                "No watermark",
                "3 font styles",
                "Email support"
            ],
            isPopular: false,
            savings: nil
        ),
        PurchaseProduct(
            id: "com.autosubtitle.subscription.pro.monthly",
            name: "Pro",
            type: .subscription,
            credits: 180,
            price: "$24.99",
            pricePerCredit: 0.139,
            features: [
                "180 videos per month",
                "HD quality",
                "No watermark",
                "All fonts",
                "Priority processing",
                "Batch processing",
                "Priority support"
            ],
            isPopular: true,
            savings: "17%"
        ),
        PurchaseProduct(
            id: "com.autosubtitle.subscription.ultimate.monthly",
            name: "Ultimate",
            type: .subscription,
            credits: 500,
            price: "$49.99",
            pricePerCredit: 0.10,
            features: [
                "500 videos per month",
                "4K quality",
                "No watermark",
                "All features",
                "API access",
                "Custom branding",
                "Dedicated support",
                "Advanced analytics"
            ],
            isPopular: false,
            savings: "40%"
        )
    ]

    // MARK: One-Time Purchases

    static let oneTimePurchases: [PurchaseProduct] = [
        PurchaseProduct(
            id: "com.autosubtitle.credits.small",
            name: "Small Pack",
            type: .oneTime,
            credits: 20,
            price: "$4.99",
            pricePerCredit: 0.25,
            features: ["20 video credits", "Never expires"],
            isPopular: false,
            savings: nil
        ),
        PurchaseProduct(
            id: "com.autosubtitle.credits.medium",
            name: "Medium Pack",
            type: .oneTime,
            credits: 75,
            price: "$14.99",
            pricePerCredit: 0.20,
            features: ["75 video credits", "Never expires", "20% savings"],
            isPopular: true,
            savings: "20%"
        ),
        PurchaseProduct(
            id: "com.autosubtitle.credits.large",
            name: "Large Pack",
            type: .oneTime,
            credits: 250,
            price: "$39.99",
            pricePerCredit: 0.16,
            features: ["250 video credits", "Never expires", "36% savings"],
            isPopular: false,
            savings: "36%"
        )
    ]

    // MARK: Helper Methods

    static func getProduct(byId id: String) -> PurchaseProduct? {
        let allProducts = subscriptions + oneTimePurchases
        return allProducts.first { $0.id == id }
    }

    static func getSubscription(forTier tier: SubscriptionTier) -> PurchaseProduct? {
        switch tier {
        case .free:
            return nil
        case .starter:
            return subscriptions[0]
        case .pro:
            return subscriptions[1]
        case .ultimate:
            return subscriptions[2]
        }
    }
}

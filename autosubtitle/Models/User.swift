//
//  User.swift
//  AutoSubtitle
//
//  User model representing application users
//

import Foundation
import FirebaseFirestore

struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var firebaseUID: String
    var creditBalance: Int
    var subscriptionTier: SubscriptionTier
    var createdAt: Date
    var lastActive: Date
    var totalVideosProcessed: Int
    var totalCreditsUsed: Int
    var totalCreditsPurchased: Int

    enum CodingKeys: String, CodingKey {
        case id
        case firebaseUID
        case creditBalance
        case subscriptionTier
        case createdAt
        case lastActive
        case totalVideosProcessed
        case totalCreditsUsed
        case totalCreditsPurchased
    }

    init(
        id: String? = nil,
        firebaseUID: String,
        creditBalance: Int = 5, // Free tier starts with 5 credits
        subscriptionTier: SubscriptionTier = .free,
        createdAt: Date = Date(),
        lastActive: Date = Date(),
        totalVideosProcessed: Int = 0,
        totalCreditsUsed: Int = 0,
        totalCreditsPurchased: Int = 0
    ) {
        self.id = id
        self.firebaseUID = firebaseUID
        self.creditBalance = creditBalance
        self.subscriptionTier = subscriptionTier
        self.createdAt = createdAt
        self.lastActive = lastActive
        self.totalVideosProcessed = totalVideosProcessed
        self.totalCreditsUsed = totalCreditsUsed
        self.totalCreditsPurchased = totalCreditsPurchased
    }

    var isSubscribed: Bool {
        subscriptionTier != .free
    }

    var hasCredits: Bool {
        creditBalance > 0
    }
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case starter = "starter"
    case pro = "pro"
    case ultimate = "ultimate"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .starter: return "Starter"
        case .pro: return "Pro"
        case .ultimate: return "Ultimate"
        }
    }

    var monthlyCredits: Int {
        switch self {
        case .free: return 5
        case .starter: return 60
        case .pro: return 180
        case .ultimate: return 500
        }
    }

    var price: String {
        switch self {
        case .free: return "$0"
        case .starter: return "$9.99"
        case .pro: return "$24.99"
        case .ultimate: return "$49.99"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "5 videos per month",
                "Standard quality",
                "Watermark included",
                "Basic fonts"
            ]
        case .starter:
            return [
                "60 videos per month",
                "HD quality",
                "No watermark",
                "3 font styles",
                "Email support"
            ]
        case .pro:
            return [
                "180 videos per month",
                "HD quality",
                "No watermark",
                "All fonts",
                "Priority processing",
                "Batch processing",
                "Priority support"
            ]
        case .ultimate:
            return [
                "500 videos per month",
                "4K quality",
                "No watermark",
                "All features",
                "API access",
                "Custom branding",
                "Dedicated support",
                "Advanced analytics"
            ]
        }
    }

    var color: String {
        switch self {
        case .free: return "gray"
        case .starter: return "blue"
        case .pro: return "purple"
        case .ultimate: return "gold"
        }
    }
}

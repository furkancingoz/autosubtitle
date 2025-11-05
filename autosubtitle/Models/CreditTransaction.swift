//
//  CreditTransaction.swift
//  AutoSubtitle
//
//  Model for credit transactions
//

import Foundation
import FirebaseFirestore

struct CreditTransaction: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var amount: Int // Positive = added, Negative = deducted
    var type: TransactionType
    var reference: String? // Video job ID or purchase receipt ID
    var timestamp: Date
    var balanceAfter: Int
    var description: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case amount
        case type
        case reference
        case timestamp
        case balanceAfter
        case description
    }

    init(
        id: String? = nil,
        userId: String,
        amount: Int,
        type: TransactionType,
        reference: String? = nil,
        timestamp: Date = Date(),
        balanceAfter: Int,
        description: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.amount = amount
        self.type = type
        self.reference = reference
        self.timestamp = timestamp
        self.balanceAfter = balanceAfter
        self.description = description
    }

    var isPositive: Bool {
        amount > 0
    }

    var displayAmount: String {
        let prefix = amount > 0 ? "+" : ""
        return "\(prefix)\(amount)"
    }

    var icon: String {
        switch type {
        case .purchase: return "creditcard.fill"
        case .subscription: return "arrow.clockwise"
        case .deduction: return "minus.circle.fill"
        case .refund: return "arrow.uturn.backward.circle.fill"
        case .bonus: return "gift.fill"
        case .adjustment: return "slider.horizontal.3"
        }
    }
}

enum TransactionType: String, Codable {
    case purchase = "purchase"           // One-time credit purchase
    case subscription = "subscription"   // Monthly subscription credits
    case deduction = "deduction"         // Credits used for video processing
    case refund = "refund"              // Credits refunded due to failure
    case bonus = "bonus"                // Promotional credits
    case adjustment = "adjustment"       // Manual adjustment by support

    var displayName: String {
        switch self {
        case .purchase: return "Purchase"
        case .subscription: return "Subscription"
        case .deduction: return "Video Processing"
        case .refund: return "Refund"
        case .bonus: return "Bonus"
        case .adjustment: return "Adjustment"
        }
    }
}

//
//  Transaction.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 09/06/25.
//

import Foundation

enum TransactionType: String, CaseIterable, Identifiable, Codable, Equatable {
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }
}

enum TransactionCategory: String, CaseIterable, Codable {
    case food
    case transport
    case shopping
    case bills
    case entertainment
    case salary
    case other

    /// The transaction type this category normally implies.
    var defaultType: TransactionType {
        self == .salary ? .income : .expense
    }
}

struct Transaction: Identifiable, Codable, Equatable {
    var id: String?
    var title: String
    var amount: Double
    var date: Date
    var type: TransactionType
    var category: TransactionCategory

    init(id: String? = UUID().uuidString,
         title: String,
         amount: Double,
         date: Date,
         type: TransactionType,
         category: TransactionCategory = .other) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
    }

    // MARK: - Group shares

    /// Personal transactions created from a group expense use the id
    /// "group_<groupID>_<expenseID>" (UUIDs never contain "_").
    static func groupShareID(groupID: String, expenseID: String) -> String {
        "group_\(groupID)_\(expenseID)"
    }

    var isGroupShare: Bool { id?.hasPrefix("group_") == true }

    var groupID: String? {
        guard isGroupShare, let parts = id?.split(separator: "_"), parts.count == 3 else { return nil }
        return String(parts[1])
    }

    /// Same content, ignoring tiny date differences from cloud round-trips.
    func matches(_ other: Transaction) -> Bool {
        id == other.id && title == other.title && type == other.type && category == other.category
            && abs(amount - other.amount) < 0.005 && abs(date.timeIntervalSince(other.date)) < 1
    }

    /// Tolerant decoding: documents saved by older app versions have no `category`,
    /// and a single bad field must never make a transaction disappear.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        amount = (try? c.decode(Double.self, forKey: .amount)) ?? 0
        date = (try? c.decode(Date.self, forKey: .date)) ?? Date()
        type = (try? c.decode(TransactionType.self, forKey: .type)) ?? .expense
        category = (try? c.decode(TransactionCategory.self, forKey: .category)) ?? .other
    }
}

//
//  GroupModels.swift
//  ExpanseTracker
//
//  Shared expenses for trips, flats, dinners… Stored in users/{uid}/groups.
//

import Foundation

struct GroupMember: Codable, Identifiable, Hashable {
    var id: String
    var name: String

    /// The signed-in user is always this member.
    static let meID = "me"
    static let me = GroupMember(id: meID, name: "You")

    var isMe: Bool { id == Self.meID }
}

struct GroupExpense: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var title: String
    var amount: Double
    var paidBy: String
    /// Member IDs sharing this expense equally. (Empty, from older data, means everyone.)
    var splitAmong: [String]
    var date: Date
    var category: TransactionCategory = .other

    init(id: String = UUID().uuidString, title: String, amount: Double, paidBy: String,
         splitAmong: [String], date: Date = Date(), category: TransactionCategory = .other) {
        self.id = id
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.splitAmong = splitAmong
        self.date = date
        self.category = category
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        amount = (try? c.decode(Double.self, forKey: .amount)) ?? 0
        paidBy = (try? c.decode(String.self, forKey: .paidBy)) ?? GroupMember.meID
        splitAmong = (try? c.decode([String].self, forKey: .splitAmong)) ?? []
        date = (try? c.decode(Date.self, forKey: .date)) ?? Date()
        category = (try? c.decode(TransactionCategory.self, forKey: .category)) ?? .other
    }
}

/// Money handed over between members to settle up (recorded in step 2).
struct GroupPayment: Codable, Identifiable, Equatable {
    var id: String = UUID().uuidString
    var from: String
    var to: String
    var amount: Double
    var date: Date = Date()
}

struct ExpenseGroup: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var emoji: String
    var members: [GroupMember]
    var expenses: [GroupExpense] = []
    var payments: [GroupPayment] = []
    var createdAt: Date = Date()

    init(name: String, emoji: String, members: [GroupMember]) {
        self.name = name
        self.emoji = emoji
        self.members = members
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(String.self, forKey: .id)) ?? UUID().uuidString
        name = (try? c.decode(String.self, forKey: .name)) ?? "Group"
        emoji = (try? c.decode(String.self, forKey: .emoji)) ?? "👥"
        members = (try? c.decode([GroupMember].self, forKey: .members)) ?? [.me]
        expenses = (try? c.decode([GroupExpense].self, forKey: .expenses)) ?? []
        payments = (try? c.decode([GroupPayment].self, forKey: .payments)) ?? []
        createdAt = (try? c.decode(Date.self, forKey: .createdAt)) ?? Date()
    }

    func name(of memberID: String) -> String {
        members.first { $0.id == memberID }?.name ?? "Former member"
    }

    /// The members an expense is split between, in group order.
    func participants(of expense: GroupExpense) -> [String] {
        let chosen = Set(expense.splitAmong)
        let ordered = members.map(\.id).filter { chosen.isEmpty || chosen.contains($0) }
        return ordered.isEmpty ? members.map(\.id) : ordered
    }

    /// A member can't be removed once money is attached to them.
    func isInvolved(_ memberID: String) -> Bool {
        expenses.contains { $0.paidBy == memberID || $0.splitAmong.contains(memberID) }
            || payments.contains { $0.from == memberID || $0.to == memberID }
    }
}

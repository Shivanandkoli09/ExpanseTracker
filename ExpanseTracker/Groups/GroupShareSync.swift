//
//  GroupShareSync.swift
//  ExpanseTracker
//
//  Turns group expenses into personal transactions for *your share only*,
//  so trips count correctly in your spending, budget and goal.
//

import Foundation

enum GroupShareSync {

    /// The personal transactions that should exist for these groups.
    /// Settlement payments are reimbursements, not income or spending, so they're ignored.
    static func desiredTransactions(for groups: [ExpenseGroup]) -> [Transaction] {
        groups.flatMap { group in
            group.expenses.compactMap { expense -> Transaction? in
                guard let myPaise = group.portions(of: expense)[GroupMember.meID], myPaise > 0 else {
                    return nil
                }
                return Transaction(
                    id: Transaction.groupShareID(groupID: group.id, expenseID: expense.id),
                    title: expense.title,
                    amount: Double(myPaise) / 100,
                    date: expense.date,
                    type: .expense,
                    category: expense.category
                )
            }
        }
    }
}

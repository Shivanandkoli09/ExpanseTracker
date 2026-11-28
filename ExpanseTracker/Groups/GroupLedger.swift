//
//  GroupLedger.swift
//  ExpanseTracker
//
//  Who paid what, who owes whom, and the fewest payments to settle up.
//  Works in paise (whole numbers) so splits always add up exactly.
//

import Foundation

struct GroupLedger {

    struct Transfer: Identifiable, Equatable {
        let from: String
        let to: String
        let amount: Double
        var id: String { "\(from)->\(to)" }
    }

    /// Everything spent by the group.
    let totalSpent: Double
    /// What each member consumed (their share of expenses).
    let shares: [String: Double]
    /// What each member paid out of pocket.
    let paid: [String: Double]
    /// Positive: should get money back. Negative: owes money. Includes recorded payments.
    let balances: [String: Double]
    /// Fewest payments that settle every balance.
    let transfers: [Transfer]

    var isSettled: Bool { transfers.isEmpty }

    func balance(of memberID: String) -> Double { balances[memberID] ?? 0 }
    func share(of memberID: String) -> Double { shares[memberID] ?? 0 }

    init(group: ExpenseGroup) {
        var share: [String: Int] = [:]
        var paid: [String: Int] = [:]
        var net: [String: Int] = [:]
        var total = 0

        for expense in group.expenses {
            let paise = Int((expense.amount * 100).rounded())
            guard paise > 0 else { continue }
            total += paise

            let people = group.participants(of: expense)
            let base = paise / people.count
            let remainder = paise % people.count
            for (index, member) in people.enumerated() {
                let portion = base + (index < remainder ? 1 : 0)
                share[member, default: 0] += portion
                net[member, default: 0] -= portion
            }
            paid[expense.paidBy, default: 0] += paise
            net[expense.paidBy, default: 0] += paise
        }

        for payment in group.payments {
            let paise = Int((payment.amount * 100).rounded())
            net[payment.from, default: 0] += paise
            net[payment.to, default: 0] -= paise
        }

        // Greedy: largest debtor pays largest creditor. At most (people - 1) payments.
        var creditors = net.filter { $0.value > 0 }.map { ($0.key, $0.value) }
        var debtors = net.filter { $0.value < 0 }.map { ($0.key, -$0.value) }
        var transfers: [Transfer] = []
        let order = Dictionary(uniqueKeysWithValues: group.members.enumerated().map { ($1.id, $0) })
        func sortKey(_ a: (String, Int), _ b: (String, Int)) -> Bool {
            a.1 != b.1 ? a.1 > b.1 : (order[a.0] ?? .max) < (order[b.0] ?? .max)
        }

        while true {
            creditors.sort(by: sortKey)
            debtors.sort(by: sortKey)
            guard let creditor = creditors.first, let debtor = debtors.first,
                  creditor.1 > 0, debtor.1 > 0 else { break }
            let amount = min(creditor.1, debtor.1)
            transfers.append(Transfer(from: debtor.0, to: creditor.0, amount: Double(amount) / 100))
            creditors[0].1 -= amount
            debtors[0].1 -= amount
            creditors.removeAll { $0.1 == 0 }
            debtors.removeAll { $0.1 == 0 }
        }

        func rupees(_ dict: [String: Int]) -> [String: Double] { dict.mapValues { Double($0) / 100 } }
        totalSpent = Double(total) / 100
        shares = rupees(share)
        self.paid = rupees(paid)
        balances = rupees(net)
        self.transfers = transfers
    }
}

//
//  SpendingSummary.swift
//  ExpanseTracker
//
//  Pure calculations behind the home screen. No UI, easy to test.
//

import Foundation

struct SpendingSummary {

    struct CategoryTotal: Identifiable {
        let category: TransactionCategory
        let amount: Double
        var id: TransactionCategory { category }
    }

    struct MonthTotal: Identifiable {
        let month: Date
        let expense: Double
        let income: Double
        var id: Date { month }
    }

    struct BudgetStatus {
        let budget: Double
        let spent: Double
        /// What can be spent per remaining day (including today) without going over.
        let safeToSpendToday: Double

        var remaining: Double { budget - spent }
        var progress: Double { budget > 0 ? spent / budget : 0 }
        var isOver: Bool { spent > budget }
    }

    struct GoalProgress {
        let target: Double
        let saved: Double
        /// `0` when reached, `nil` when the current pace never gets there.
        let monthsToGo: Int?

        var progress: Double { target > 0 ? min(1, saved / target) : 0 }
        var isReached: Bool { saved >= target }
    }

    let monthStart: Date
    let monthExpense: Double
    let monthIncome: Double
    let lastMonthExpense: Double
    let allTimeBalance: Double
    /// This month's expenses by category, largest first.
    let categoryTotals: [CategoryTotal]
    /// Last 6 months, oldest first.
    let trend: [MonthTotal]
    /// Days left in the current month, including today.
    let daysLeftInMonth: Int
    /// Consecutive days with at least one transaction, ending today
    /// (or yesterday, so the streak survives until today is over).
    let loggingStreak: Int

    var monthNet: Double { monthIncome - monthExpense }

    init(transactions: [Transaction], now: Date = Date(), calendar: Calendar = .current) {
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        self.monthStart = monthStart

        func inMonth(_ date: Date, _ start: Date) -> Bool {
            calendar.isDate(date, equalTo: start, toGranularity: .month)
        }
        func total(_ txns: [Transaction], _ type: TransactionType) -> Double {
            txns.lazy.filter { $0.type == type }.reduce(0) { $0 + $1.amount }
        }

        let thisMonth = transactions.filter { inMonth($0.date, monthStart) }
        monthExpense = total(thisMonth, .expense)
        monthIncome = total(thisMonth, .income)

        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        lastMonthExpense = total(transactions.filter { inMonth($0.date, lastMonthStart) }, .expense)

        allTimeBalance = transactions.reduce(0) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }

        categoryTotals = Dictionary(grouping: thisMonth.filter { $0.type == .expense }, by: \.category)
            .map { CategoryTotal(category: $0.key, amount: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.amount > $1.amount }

        trend = (0..<6).reversed().compactMap { offset in
            guard let start = calendar.date(byAdding: .month, value: -offset, to: monthStart) else { return nil }
            let txns = transactions.filter { inMonth($0.date, start) }
            return MonthTotal(month: start, expense: total(txns, .expense), income: total(txns, .income))
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        daysLeftInMonth = max(1, daysInMonth - calendar.component(.day, from: now) + 1)

        let loggedDays = Set(transactions.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: now)
        if !loggedDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        var streak = 0
        while loggedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        loggingStreak = streak
    }

    func budgetStatus(budget: Double) -> BudgetStatus {
        let remaining = max(0, budget - monthExpense)
        return BudgetStatus(
            budget: budget,
            spent: monthExpense,
            safeToSpendToday: remaining / Double(daysLeftInMonth)
        )
    }

    /// "Saved" = everything earned minus everything spent in MyMoney so far.
    /// Pace = this month's net savings.
    func goalProgress(target: Double) -> GoalProgress {
        let saved = max(0, allTimeBalance)
        let stillNeeded = target - saved
        let months: Int?
        if stillNeeded <= 0 {
            months = 0
        } else if monthNet > 0 {
            months = Int((stillNeeded / monthNet).rounded(.up))
        } else {
            months = nil
        }
        return GoalProgress(target: target, saved: saved, monthsToGo: months)
    }
}

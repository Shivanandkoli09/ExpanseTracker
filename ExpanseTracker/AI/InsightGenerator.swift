//
//  InsightGenerator.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

final class InsightGenerator {

    static func generateInsights(from transactions: [Transaction]) -> [Insight] {
        
        var insights: [Insight] = []
        let calendar = Calendar.current
        let now = Date()

        // MARK: - This Month Transactions
        let thisMonth = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }

        // MARK: - Last Month Transactions
        let lastMonth = transactions.filter {
            guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
            return calendar.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month)
        }

        // MARK: - Total Spending
        let thisMonthTotal = thisMonth
            .filter { $0.type == .expanse }
            .map { $0.amount }
            .reduce(0, +)

        let lastMonthTotal = lastMonth
            .filter { $0.type == .expanse }
            .map { $0.amount }
            .reduce(0, +)

        // MARK: - Monthly Comparison
        if lastMonthTotal > 0 {
            let change = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100
            
            if change > 0 {
                insights.append(Insight(message: "You spent \(Int(change))% more than last month"))
            } else if change < 0 {
                insights.append(Insight(message: "You spent \(Int(abs(change)))% less than last month"))
            }
        }

        // MARK: - Category Totals
        let expenses = thisMonth.filter { $0.type == .expanse }

        let categoryTotals = Dictionary(grouping: expenses) { $0.category }
            .mapValues { $0.map { $0.amount }.reduce(0, +) }

        // Highest spending category
        if let topCategory = categoryTotals.max(by: { $0.value < $1.value }) {
            insights.append(
                Insight(message: "You spent most on \(topCategory.key.rawValue.capitalized)")
            )
        }

        // MARK: - Most Frequent Category
        let categoryCounts = Dictionary(grouping: expenses) { $0.category }
            .mapValues { $0.count }

        if let frequentCategory = categoryCounts.max(by: { $0.value < $1.value }) {
            insights.append(
                Insight(message: "\(frequentCategory.key.rawValue.capitalized) is your most frequent expense")
            )
        }

        // MARK: - Average Daily Spend
        let days = Set(expenses.map { calendar.startOfDay(for: $0.date) }).count
        if days > 0 {
            let avg = thisMonthTotal / Double(days)
            insights.append(
                Insight(message: "Your average daily spend is ₹\(Int(avg))")
            )
        }

        // MARK: - Largest Expense
        if let maxTxn = expenses.max(by: { $0.amount < $1.amount }) {
            insights.append(
                Insight(message: "Your biggest expense was ₹\(Int(maxTxn.amount)) on \(maxTxn.category.rawValue.capitalized)")
            )
        }

        // MARK: - Simple Spending Warning
        if thisMonthTotal > 0 && thisMonthTotal > (lastMonthTotal * 1.5) {
            insights.append(
                Insight(message: "⚠️ Your spending increased significantly this month")
            )
        }

        return insights
    }
}

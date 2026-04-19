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

        // MARK: - This Week Transactions
        let thisWeek = transactions.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .weekOfYear)
        }

        // MARK: - Last Week Transactions
        let lastWeek = transactions.filter {
            guard let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return false }
            return calendar.isDate($0.date, equalTo: lastWeekDate, toGranularity: .weekOfYear)
        }

        // MARK: - Total Spending
        let thisWeekTotal = thisWeek
            .filter { $0.type == .expanse }
            .map { $0.amount }
            .reduce(0, +)

        let lastWeekTotal = lastWeek
            .filter { $0.type == .expanse }
            .map { $0.amount }
            .reduce(0, +)

        // MARK: - Spending Comparison
        if lastWeekTotal > 0 {
            let change = ((thisWeekTotal - lastWeekTotal) / lastWeekTotal) * 100
            
            if change > 0 {
                insights.append(Insight(message: "You spent \(Int(change))% more than last week"))
            } else if change < 0 {
                insights.append(Insight(message: "You spent \(Int(abs(change)))% less than last week"))
            }
        }

        // MARK: - Category Analysis
        let categoryTotals = Dictionary(grouping: thisWeek.filter { $0.type == .expanse }) {
            $0.category
        }.mapValues { $0.map { $0.amount }.reduce(0, +) }

        if let topCategory = categoryTotals.max(by: { $0.value < $1.value }) {
            insights.append(
                Insight(message: "Your highest spending is on \(topCategory.key.rawValue.capitalized)")
            )
        }

        // MARK: - Food Insight Example
        if let foodTotal = categoryTotals[.food], foodTotal > 0 {
            insights.append(
                Insight(message: "You spent ₹\(Int(foodTotal)) on Food this week")
            )
        }

        return insights
    }
}

//
//  HomeViewModel.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var summary = SpendingSummary(transactions: [])
    @Published private(set) var insights: [Insight] = []

    func update(transactions: [Transaction], goal: SavingGoal?, goalTarget: Double?) {
        let summary = SpendingSummary(transactions: transactions)
        self.summary = summary

        var insights: [Insight] = []
        if let goal {
            insights.append(goalInsight(goal: goal, target: goalTarget, summary: summary))
        }
        insights += InsightGenerator.generateInsights(from: transactions)
        self.insights = insights
    }

    /// Ties this month's behaviour back to *why* the user is saving.
    private func goalInsight(goal: SavingGoal, target: Double?, summary: SpendingSummary) -> Insight {
        let net = summary.monthNet
        guard net > 0 else {
            return Insight(
                message: "\(goal.emoji) You've spent more than you earned this month. Small cuts will get your \(goal.title) back on track.",
                type: .warning
            )
        }
        if let target, target > 0 {
            let share = Int((net / target * 100).rounded())
            return Insight(
                message: "\(goal.emoji) You saved \(Currency.string(net.rounded())) this month — \(share)% of your \(goal.title) target.",
                type: .positive
            )
        }
        return Insight(
            message: "\(goal.emoji) You saved \(Currency.string(net.rounded())) this month towards your \(goal.title).",
            type: .positive
        )
    }
}

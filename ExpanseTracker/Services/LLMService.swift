//
//  LLMService.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

final class LLMService {

    static let shared = LLMService()

    private init() {}

    // MARK: - Generate AI Insight
    func generateInsight(from transactions: [Transaction]) async -> String {
        
        // 🔴 MOCK RESPONSE (we’ll replace with real API later)
        return generateMockInsight(from: transactions)
    }

    private func generateMockInsight(from transactions: [Transaction]) -> String {
        
        let expenses = transactions.filter { $0.type == .expanse }
        let total = expenses.map { $0.amount }.reduce(0, +)

        if total > 10000 {
            return "You are spending quite heavily this month. Try reducing unnecessary expenses."
        } else {
            return "Your spending looks balanced. Keep maintaining this habit."
        }
    }
}

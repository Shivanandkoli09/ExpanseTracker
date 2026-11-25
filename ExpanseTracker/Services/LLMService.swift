//
//  LLMService.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

import Foundation

final class LLMService {

    static let shared = LLMService()
    private init() {}

    // MARK: - Public API
    func generateInsights(from transactions: [Transaction]) -> [String] {
        
        guard !transactions.isEmpty else {
            return ["Start tracking your expenses to get insights."]
        }

        var insights: [String] = []

        // 🔹 Monthly comparison
        if let comparison = compareWithLastMonth(transactions) {
            insights.append(comparison)
        }

        let expenses = transactions.filter { $0.type == .expanse }
        let total = expenses.map { $0.amount }.reduce(0, +)

        let categorySpending = Dictionary(grouping: expenses) { $0.category }
            .mapValues { $0.map { $0.amount }.reduce(0, +) }

        let topCategory = categorySpending.max { $0.value < $1.value }

        // 🔹 High spending insight
        if total > 10000 {
            insights.append("You’ve been spending more than usual this month. Consider reducing unnecessary expenses.")
        }

        // 🔹 Top category insight
        if let top = topCategory {
            insights.append("Most of your spending is on \(top.key.rawValue.capitalized). Try optimizing this category.")
        }

        // 🔹 Positive feedback
        if total < 3000 {
            insights.append("Great job! Your spending is well under control.")
        }

        return insights
    }

    // MARK: - Monthly Comparison
    private func compareWithLastMonth(_ transactions: [Transaction]) -> String? {
        
        let calendar = Calendar.current

        let currentMonth = transactions.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }

        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: Date()) else {
            return nil
        }

        let lastMonth = transactions.filter {
            calendar.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month)
        }

        let currentTotal = currentMonth.map { $0.amount }.reduce(0, +)
        let lastTotal = lastMonth.map { $0.amount }.reduce(0, +)

        guard lastTotal > 0 else { return nil }

        let change = ((currentTotal - lastTotal) / lastTotal) * 100

        if change > 20 {
            return "Your spending increased by \(Int(change))% compared to last month."
        } else if change < -20 {
            return "Great! You reduced your spending by \(Int(abs(change)))% compared to last month."
        }

        return nil
    }
}


//final class LLMService {
//
//    static let shared = LLMService()
//
//    private init() {}
//
//    func generateInsight(from transactions: [Transaction]) async -> String {
//
//        let summary = buildSummary(from: transactions)
//
//        let prompt = """
//        Analyze the following user expenses and provide a short financial insight:
//
//        \(summary)
//
//        Keep it short and helpful.
//        """
//
//        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
//            return "Invalid URL"
//        }
//
//        let requestBody = OpenAIRequest(
//            model: "gpt-4o-mini",
//            messages: [
//                Message(role: "user", content: prompt)
//            ]
//        )
//
//        guard let jsonData = try? JSONEncoder().encode(requestBody) else {
//            return "Encoding error"
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("Bearer \(Config.openAIKey)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.httpBody = jsonData
//
//        do {
//            let (data, _) = try await URLSession.shared.data(for: request)
//
//            // 🔍 Print raw response
//            if let raw = String(data: data, encoding: .utf8) {
//                print("📦 OpenAI Raw:", raw)
//            }
//
//            // ✅ Try success response
//            if let success = try? JSONDecoder().decode(OpenAIResponse.self, from: data) {
//                return success.choices.first?.message.content ?? "No insight"
//            }
//
//            // ❌ If not success → decode error
//            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
//                return "Error: \(errorResponse.error.message)"
//            }
//
//            return "Unknown response format"
//
//        } catch {
//            print("❌ Network Error:", error)
//            return "Network error"
//        }
//    }
//
//    // MARK: - Convert Transactions to Text
//    private func buildSummary(from transactions: [Transaction]) -> String {
//        let expenses = transactions.filter { $0.type == .expanse }
//
//        let total = expenses.map { $0.amount }.reduce(0, +)
//
//        let categories = Dictionary(grouping: expenses) { $0.category }
//            .mapValues { $0.map { $0.amount }.reduce(0, +) }
//
//        let categorySummary = categories.map {
//            "\($0.key.rawValue): ₹\(Int($0.value))"
//        }.joined(separator: ", ")
//
//        return """
//        Total Spending: ₹\(Int(total))
//        Category Breakdown: \(categorySummary)
//        """
//    }
//}

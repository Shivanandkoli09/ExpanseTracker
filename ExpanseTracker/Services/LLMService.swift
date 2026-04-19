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

//
//  HomeViewModel.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

final class HomeViewModel: ObservableObject {

    @Published var insights: [Insight] = []
    @Published var aiInsights: [String] = []   // ✅ plural

    func generateInsights(from transactions: [Transaction]) {
        insights = InsightGenerator.generateInsights(from: transactions)
    }

    func generateAIInsights(from transactions: [Transaction]) {
        aiInsights = LLMService.shared.generateInsights(from: transactions)
    }
}

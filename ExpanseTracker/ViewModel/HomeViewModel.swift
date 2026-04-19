//
//  HomeViewModel.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

final class HomeViewModel: ObservableObject {

    @Published var insights: [Insight] = []
    @Published var aiInsight: String = ""

    func generateInsights(from transactions: [Transaction]) {
        insights = InsightGenerator.generateInsights(from: transactions)
    }
    
    func generateAIInsight(from transactions: [Transaction]) {
        Task {
            let result = await LLMService.shared.generateInsight(from: transactions)
            
            DispatchQueue.main.async {
                self.aiInsight = result
            }
        }
    }
}

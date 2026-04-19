//
//  HomeViewModel.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import Foundation

final class HomeViewModel: ObservableObject {

    @Published var insights: [Insight] = []

    func generateInsights(from transactions: [Transaction]) {
        insights = InsightGenerator.generateInsights(from: transactions)
    }
}

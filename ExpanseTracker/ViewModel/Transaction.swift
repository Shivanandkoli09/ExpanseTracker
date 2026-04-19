//
//  Transaction.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import Foundation
import FirebaseFirestore

enum TransactionType: String, CaseIterable, Identifiable, Codable, Equatable {
    case income = "Income"
    case expanse = "Expense"
    
    var id: String { self.rawValue }
}

enum TransactionCategory: String, CaseIterable, Codable {
    case food
    case transport
    case shopping
    case bills
    case entertainment
    case salary
    case other
}

struct Transaction: Identifiable, Codable, Equatable {
    var id: String?
    let title: String
    let amount: Double
    let date: Date
    let type: TransactionType
    let category: TransactionCategory
    
    init(id: String? = UUID().uuidString, titile: String, amount: Double, date: Date, type: TransactionType, category: TransactionCategory = .other) {
        self.id = id
        self.title = titile
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
    }
    
}

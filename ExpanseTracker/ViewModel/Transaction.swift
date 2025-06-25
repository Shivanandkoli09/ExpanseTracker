//
//  Transaction.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import Foundation

enum TransactionType: String, CaseIterable, Identifiable, Codable, Equatable {
    case income = "Income"
    case expanse = "Expense"
    
    var id: String { self.rawValue }
}

struct Transaction: Identifiable, Codable, Equatable {
    let id: UUID
    let titile: String
    let amount: Double
    let date: Date
    let type: TransactionType
    
    init(id: UUID = UUID(), titile: String, amount: Double, date: Date, type: TransactionType) {
        self.id = id
        self.titile = titile
        self.amount = amount
        self.date = date
        self.type = type
    }
    
}

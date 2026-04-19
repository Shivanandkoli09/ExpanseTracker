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

struct Transaction: Identifiable, Codable, Equatable {
    var id: String?
    let title: String
    let amount: Double
    let date: Date
    let type: TransactionType
    
    init(id: String? = UUID().uuidString, titile: String, amount: Double, date: Date, type: TransactionType) {
        self.id = id
        self.title = titile
        self.amount = amount
        self.date = date
        self.type = type
    }
    
}

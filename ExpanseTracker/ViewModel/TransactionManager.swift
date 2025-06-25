//
//  TransactionManager.swift
//  ExpanseTracker
//
//  Created by KPIT on 10/06/25.
//

import Foundation

class TransactionManager: ObservableObject {
    
    @Published var transactions: [Transaction] = [] {
        didSet {
            save()
        }
    }
    
    private let key = "transaction"
    
    init() {
        load()
    }
    
    func add(_ transaction: Transaction){
        transactions.append(transaction)
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: key), let savedTransactions = try? JSONDecoder().decode([Transaction].self, from: data) {
            self.transactions = savedTransactions
        }
    }
}

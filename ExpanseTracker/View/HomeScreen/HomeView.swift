//
//  HomeView.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import SwiftUI

enum TransactionFilter: String, CaseIterable, Identifiable {
    
    case all = "All"
    case income = "Income"
    case expanse = "Expense"
    
    var id: String {
        self.rawValue
    }
}

struct HomeView: View {
    @State private var transactions: [Transaction] = []
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: Transaction?
    @State private var isEditing: Bool = false
    
    @EnvironmentObject  var transactionManager: TransactionManager
    
    var filteredTransactions: [Transaction] {
        let filtered: [Transaction]
        
        switch selectedFilter {
        case .all:
            filtered = transactionManager.transactions
        case .income:
            filtered = transactionManager.transactions.filter {
                $0.type == .income
            }
        case .expanse:
            filtered = transactionManager.transactions.filter {
                $0.type == .expanse
            }
        }
        
        return filtered.sorted { $0.date > $1.date }
    }
    var body: some View {
        VStack {
            summaryCard()
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(TransactionFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            List {
                ForEach(groupedTransactions, id: \.0) { (month, transactions) in
                    Section(header: Text(month).font(.headline)) {
                        ForEach(transactions) { txn in
                            TransactionRowView(txn: txn)
                                .onTapGesture {
                                    selectedTransaction = txn
//                                    isEditing = true
                                }
                        }
                        .onDelete { indexSet in
                            deleteTransaction(from: transactions, at: indexSet)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
        .navigationBarTitle("MyMoney", displayMode: .inline)
        .sheet(item: $selectedTransaction) { txn in 
            NavigationStack {
                AddTransactionView(manager: transactionManager, existingTransaction: txn)
            }
        }
        .toolbar {
            NavigationLink(destination: AddTransactionView(manager: transactionManager)) {
                Image(systemName: "plus")
            }
        }
    }

    private var totalIncome: Double {
        transactionManager.transactions
            .filter { $0.type == .income }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    private var totalExpanse: Double {
        transactionManager.transactions
            .filter { $0.type == .expanse }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    private func calculateBalance() -> Double {
        totalIncome - totalExpanse
    }
    
    private func deleteTransaction(from group: [Transaction], at offsets: IndexSet) {
        for index in offsets {
            let txnToDelete = group[index]
            if let actualIndex = transactionManager.transactions.firstIndex(where: { $0.id == txnToDelete.id }) {
                transactionManager.transactions.remove(at: actualIndex)
            }
        }
    }
    private func getCurrentFilteredList() -> [Transaction] {
        switch selectedFilter {
        case .all:
            return transactionManager.transactions.sorted { $0.date > $1.date }
        case .income:
            return transactionManager.transactions.filter {
                $0.type == .income
            }.sorted { $0.date > $1.date }
        case .expanse:
            return transactionManager.transactions.filter {
                $0.type == .expanse
            }.sorted { $0.date > $1.date }
        }
    }
    
    private func summaryCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Balance")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
            Text("\u{20B9}\(calculateBalance(), specifier: "%.2f")")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(calculateBalance() >= 0 ? .green : .red)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Income")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Text("\u{20B9}\(totalIncome, specifier: "%2.f")")
                        .font(.headline)
                }
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Expense")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Text("\u{20B9}\(totalExpanse, specifier: "%2.f")")
                        .font(.headline)
                }
                
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    private var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: filteredTransactions) { txn in
            formatter.string(from: txn.date)
        }

        // Sorted by month (newest first)
        let sorted = grouped.sorted { lhs, rhs in
            guard let lhsDate = formatter.date(from: lhs.key),
                  let rhsDate = formatter.date(from: rhs.key) else {
                return false
            }
            return lhsDate > rhsDate
        }

        return sorted
    }
    
}



#Preview {
    HomeView()
}

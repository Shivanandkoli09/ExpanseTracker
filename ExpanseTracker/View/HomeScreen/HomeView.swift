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
    case expense = "Expense"
    
    var id: String {
        self.rawValue
    }
}

struct HomeView: View {
    @State private var selectedFilter: TransactionFilter = .all
    @State private var selectedTransaction: Transaction?
    @State private var isEditing: Bool = false
    @State private var searchText: String = ""
    
    @EnvironmentObject var transactionManager: TransactionManager
    @EnvironmentObject var authViewModel: SignInViewModel
    
    @StateObject private var viewModel = HomeViewModel()
    
    var filteredTransactions: [Transaction] {
        let filtered: [Transaction]
        
        switch selectedFilter {
        case .all:
            filtered = transactionManager.transactions
        case .income:
            filtered = transactionManager.transactions.filter {
                $0.type == .income
            }
        case .expense:
            filtered = transactionManager.transactions.filter {
                $0.type == .expense
            }
        }
        
        let sorted = filtered.sorted { $0.date > $1.date }
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { txn in
                let amountString = String(format: "%.2f", txn.amount)
                let dateString = DateFormatter.localizedString(from: txn.date, dateStyle: .medium, timeStyle: .none)
                return txn.title.localizedCaseInsensitiveContains(searchText) ||
                amountString.localizedCaseInsensitiveContains(searchText) ||
                dateString.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        
    }
    var body: some View {
        List {

            // 🔹 Header Section (Summary + Insights + Filter)
            Section {
                summaryCard()
                

                InsightsScrollView(insights: viewModel.insights)
                ShowAIInsightsView(aiInsights: viewModel.aiInsights)

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            // 🔹 Transactions Section
            ForEach(groupedTransactions, id: \.0) { (month, transactions) in
                Section(header: Text(month).font(.headline)) {
                    ForEach(transactions) { txn in
                        TransactionRowView(txn: txn)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                Button(role: .destructive) {
                                    if let index = transactions.firstIndex(where: { $0.id == txn.id }) {
                                        deleteTransaction(from: transactions, at: IndexSet(integer: index))
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    selectedTransaction = txn
                                    isEditing = true
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)

        // ✅ Attach searchable to MAIN container (fixes your issue)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Transaction"
        )

        // ✅ Lifecycle
        .onAppear {
            viewModel.generateInsights(from: transactionManager.transactions)
            viewModel.generateAIInsights(from: transactionManager.transactions)
        }

        .onChange(of: transactionManager.transactions) { _, newValue in
            viewModel.generateInsights(from: newValue)
            viewModel.generateAIInsights(from: newValue)
        }

        // ✅ Navigation
        .navigationBarTitle("MyMoney", displayMode: .inline)

        .sheet(item: $selectedTransaction) { txn in
            NavigationStack {
                AddTransactionView(manager: transactionManager, existingTransaction: txn)
            }
        }

        // ✅ Toolbar
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(
                    destination: AddTransactionView(manager: transactionManager)
                ) {
                    Image(systemName: "plus")
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    authViewModel.logout()
                }) {
                    Image(systemName: "person.crop.circle.fill")
                }
            }
        }
    }

    private var totalIncome: Double {
        transactionManager.transactions
            .filter { $0.type == .income }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    private var totalExpense: Double {
        transactionManager.transactions
            .filter { $0.type == .expense }
            .map { $0.amount }
            .reduce(0, +)
    }
    
    private func calculateBalance() -> Double {
        totalIncome - totalExpense
    }
    
    private func deleteTransaction(from group: [Transaction], at offsets: IndexSet) {
        for index in offsets {
            transactionManager.delete(group[index])
        }
    }
    
    struct ShowAIInsightsView: View {
        let aiInsights: [String]
        
        var body: some View {
            if !aiInsights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(aiInsights.count == 1 ? "AI Insight" : "AI Insights")
                        .font(.headline)
                        .padding(.horizontal)

                    if aiInsights.count == 1 {
                        Text(aiInsights.first!)
                            .font(.subheadline)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        ForEach(aiInsights, id: \.self) { insight in
                            Text("• \(insight)")
                                .font(.subheadline)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    
    struct InsightsScrollView: View {

        let insights: [Insight]

        var body: some View {
            if !insights.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(insights) { insight in
                            InsightCardView(insight: insight)
                                .frame(width: 220)
                        }
                    }
                    .padding(.horizontal)
                }
            }
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
                    Text("\u{20B9}\(totalIncome, specifier: "%.2f")")
                        .font(.headline)
                }
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Expense")
                        .font(.subheadline)
                        .foregroundColor(.red)
                    Text("\u{20B9}\(totalExpense, specifier: "%.2f")")
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

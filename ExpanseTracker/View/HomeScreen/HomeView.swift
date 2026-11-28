//
//  HomeView.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 09/06/25.
//

import SwiftUI

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"

    var id: String { rawValue }
}

struct HomeView: View {

    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var authViewModel: SignInViewModel
    @EnvironmentObject private var profileStore: UserProfileStore

    @StateObject private var viewModel = HomeViewModel()

    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    @State private var editingTransaction: Transaction?
    @State private var isAddingTransaction = false
    @State private var isShowingProfile = false
    @State private var isEditingBudget = false
    @State private var isEditingGoal = false

    private var isSearching: Bool { !searchText.isEmpty }

    var body: some View {
        List {
            if !isSearching {
                dashboard
            }

            Section {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TransactionFilter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

            if monthGroups.isEmpty {
                Section {
                    emptyState
                }
                .listRowBackground(Color.clear)
            }

            ForEach(monthGroups, id: \.month) { group in
                Section {
                    ForEach(group.transactions) { txn in
                        Button {
                            editingTransaction = txn
                        } label: {
                            TransactionRowView(txn: txn)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                transactionManager.delete(txn)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                editingTransaction = txn
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(Brand.primary)
                        }
                    }
                } header: {
                    monthHeader(group)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search title, amount or date")
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            // The empty state has its own "Add Transaction" button.
            if !transactionManager.transactions.isEmpty {
                addButton
            }
        }
        .navigationTitle(greetingTitle)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingProfile = true
                } label: {
                    Text(initial)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Brand.gradient))
                }
                .accessibilityLabel("Profile")
            }
        }
        .onAppear(perform: refresh)
        .onChange(of: transactionManager.transactions) { _, _ in refresh() }
        .onChange(of: profileStore.savingGoal) { _, _ in refresh() }
        .onChange(of: profileStore.goalTarget) { _, _ in refresh() }
        .sheet(isPresented: $isAddingTransaction) {
            NavigationStack {
                AddTransactionView(manager: transactionManager)
            }
        }
        .sheet(item: $editingTransaction) { txn in
            NavigationStack {
                AddTransactionView(manager: transactionManager, existingTransaction: txn)
            }
        }
        .sheet(isPresented: $isShowingProfile) {
            ProfileView()
                .environmentObject(transactionManager)
                .environmentObject(authViewModel)
                .environmentObject(profileStore)
        }
        .sheet(isPresented: $isEditingBudget) {
            BudgetSheet(currentBudget: profileStore.monthlyBudget, averageSpend: averageMonthlySpend) {
                profileStore.setMonthlyBudget($0)
            }
        }
        .sheet(isPresented: $isEditingGoal) {
            GoalSheet(goal: profileStore.savingGoal, target: profileStore.goalTarget) { goal, target in
                profileStore.setSavingGoal(goal, target: target)
            }
        }
    }

    // MARK: - Dashboard

    @ViewBuilder
    private var dashboard: some View {
        Section {
            MonthOverviewCard(summary: viewModel.summary, budget: profileStore.monthlyBudget) {
                isEditingBudget = true
            }
            SavingGoalCard(
                goal: profileStore.savingGoal,
                target: profileStore.goalTarget,
                summary: viewModel.summary
            ) {
                isEditingGoal = true
            }
            if !viewModel.insights.isEmpty {
                InsightsScrollView(insights: viewModel.insights)
            }
            if !transactionManager.transactions.isEmpty {
                SpendingChartCard(summary: viewModel.summary)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
    }

    private var emptyState: some View {
        Group {
            if isSearching {
                ContentUnavailableView.search(text: searchText)
            } else {
                ContentUnavailableView {
                    Label(selectedFilter == .all ? "No transactions yet" : "No \(selectedFilter.rawValue.lowercased()) yet",
                          systemImage: "tray")
                } description: {
                    Text("Tap + to add one. Type a title like \"Swiggy dinner\" and we'll categorise it for you.")
                } actions: {
                    Button("Add Transaction") { isAddingTransaction = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var addButton: some View {
        Button {
            isAddingTransaction = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Brand.gradient))
                .shadow(color: Brand.primary.opacity(0.4), radius: 10, y: 5)
        }
        .buttonStyle(PressableButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 8)
        .accessibilityLabel("Add transaction")
    }

    private func monthHeader(_ group: MonthGroup) -> some View {
        HStack {
            Text(group.month.formatted(.dateTime.month(.wide).year()))
            Spacer()
            if group.expense > 0 {
                Text("−" + Currency.string(group.expense))
                    .monospacedDigit()
            }
        }
        .font(.subheadline.weight(.semibold))
        .textCase(nil)
    }

    // MARK: - Data

    private struct MonthGroup {
        let month: Date
        let transactions: [Transaction]
        var expense: Double {
            transactions.lazy.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
        }
    }

    private var filteredTransactions: [Transaction] {
        let byType = transactionManager.transactions.filter { txn in
            switch selectedFilter {
            case .all: return true
            case .income: return txn.type == .income
            case .expense: return txn.type == .expense
            }
        }
        guard isSearching else { return byType }

        return byType.filter { txn in
            txn.title.localizedCaseInsensitiveContains(searchText)
                || txn.category.displayName.localizedCaseInsensitiveContains(searchText)
                || String(format: "%.0f", txn.amount).contains(searchText)
                || txn.date.formatted(date: .abbreviated, time: .omitted).localizedCaseInsensitiveContains(searchText)
        }
    }

    private var monthGroups: [MonthGroup] {
        let calendar = Calendar.current
        return Dictionary(grouping: filteredTransactions) { txn in
            calendar.dateInterval(of: .month, for: txn.date)?.start ?? txn.date
        }
        .map { MonthGroup(month: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
        .sorted { $0.month > $1.month }
    }

    private var averageMonthlySpend: Double {
        let past = viewModel.summary.trend.dropLast().filter { $0.expense > 0 }
        guard !past.isEmpty else { return 0 }
        return past.map(\.expense).reduce(0, +) / Double(past.count)
    }

    private var firstName: String? {
        authViewModel.displayName?
            .split(separator: " ")
            .first
            .map(String.init)
    }

    private var greetingTitle: String {
        firstName.map { "Hi, \($0)" } ?? "MyMoney"
    }

    private var initial: String {
        (firstName?.first).map { String($0).uppercased() } ?? "?"
    }

    private func refresh() {
        viewModel.update(
            transactions: transactionManager.transactions,
            goal: profileStore.savingGoal,
            goalTarget: profileStore.goalTarget
        )
    }
}

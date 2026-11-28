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
    @EnvironmentObject private var appLock: AppLockManager
    @EnvironmentObject private var groupsStore: GroupsStore

    @StateObject private var viewModel = HomeViewModel()

    @State private var selectedFilter: TransactionFilter = .all
    @State private var searchText = ""
    @State private var editingTransaction: Transaction?
    @State private var isAddingTransaction = false
    @State private var isShowingProfile = false
    @State private var isEditingBudget = false
    @State private var isEditingGoal = false
    @State private var recentlyDeleted: Transaction?
    @State private var isShowingGroups = false
    @State private var openGroup: GroupRoute?

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
                        if txn.isGroupShare {
                            // Edited in the group, so the two never disagree.
                            Button {
                                if let id = txn.groupID { openGroup = GroupRoute(id: id) }
                            } label: {
                                TransactionRowView(txn: txn, groupName: txn.groupID.flatMap { groupsStore.group(withID: $0)?.name } ?? "Group")
                            }
                            .buttonStyle(.plain)
                        } else {
                        Button {
                            editingTransaction = txn
                        } label: {
                            TransactionRowView(txn: txn)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(txn)
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
            VStack(alignment: .trailing, spacing: 12) {
                // The empty state has its own "Add Transaction" button.
                if !transactionManager.transactions.isEmpty {
                    addButton
                }
                if let deleted = recentlyDeleted {
                    undoToast(for: deleted)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: recentlyDeleted?.id)
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
        .navigationDestination(isPresented: $isShowingGroups) {
            GroupsListView()
        }
        .navigationDestination(item: $openGroup) { route in
            GroupDetailView(groupID: route.id)
        }
        .sheet(isPresented: $isAddingTransaction) {
            NavigationStack {
                AddTransactionView(manager: transactionManager)
            }
        }
        .sheet(item: $editingTransaction) { txn in
            NavigationStack {
                AddTransactionView(manager: transactionManager, existingTransaction: txn) { deleted in
                    delete(deleted)
                }
            }
        }
        .sheet(isPresented: $isShowingProfile) {
            ProfileView()
                .environmentObject(transactionManager)
                .environmentObject(authViewModel)
                .environmentObject(profileStore)
                .environmentObject(appLock)
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
            if viewModel.summary.loggingStreak >= 2 {
                streakChip(viewModel.summary.loggingStreak)
            }
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
            GroupsEntryCard(groups: groupsStore.groups) {
                isShowingGroups = true
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

    private func streakChip(_ days: Int) -> some View {
        HStack(spacing: 6) {
            Text("🔥")
            Text("\(days)-day logging streak")
                .fontWeight(.semibold)
            Text("· keep it going!")
                .foregroundStyle(.secondary)
        }
        .font(.footnote)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .combine)
    }

    private func undoToast(for txn: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundStyle(.secondary)
            Text("Deleted \"\(txn.title)\"")
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo") {
                transactionManager.add(txn)
                recentlyDeleted = nil
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Brand.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    /// Deletes immediately, with a few seconds to undo.
    private func delete(_ txn: Transaction) {
        transactionManager.delete(txn)
        recentlyDeleted = txn
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        let deletedID = txn.id
        Task {
            try? await Task.sleep(for: .seconds(4))
            if recentlyDeleted?.id == deletedID { recentlyDeleted = nil }
        }
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

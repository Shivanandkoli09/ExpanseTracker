//
//  GroupDetailView.swift
//  ExpanseTracker
//

import SwiftUI

struct GroupDetailView: View {
    let groupID: String

    @EnvironmentObject private var store: GroupsStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var authViewModel: SignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isAddingExpense = false
    @State private var editingExpense: GroupExpense?
    @State private var isEditingGroup = false
    @State private var isConfirmingDelete = false
    @State private var isSettlingUp = false

    var body: some View {
        if let group = store.group(withID: groupID) {
            content(group)
        } else {
            ContentUnavailableView("Group not found", systemImage: "person.3")
        }
    }

    private func content(_ group: ExpenseGroup) -> some View {
        let ledger = GroupLedger(group: group)

        return List {
            Section {
                summaryCard(group, ledger)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

            if !group.expenses.isEmpty {
                Section {
                    ForEach(group.members) { member in
                        memberBalanceRow(member, ledger)
                    }
                } header: {
                    Text("Balances")
                } footer: {
                    Text("Only your share (\(Currency.string(ledger.share(of: GroupMember.meID)))) counts towards your MyMoney spending and budget.")
                }
            }

            Section {
                if group.expenses.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "receipt")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No expenses yet")
                            .font(.headline)
                        Text("Add the first one. Choose who paid and who it's split between.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add Expense") { isAddingExpense = true }
                            .buttonStyle(.borderedProminent)
                            .tint(Brand.primary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(group.expenses.sorted { $0.date > $1.date }) { expense in
                        Button {
                            editingExpense = expense
                        } label: {
                            expenseRow(expense, in: group)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                store.deleteExpense(expense, in: groupID)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                if !group.expenses.isEmpty {
                    Text("Expenses (\(group.expenses.count))")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        isEditingGroup = true
                    } label: {
                        Label("Edit Group", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("Delete Group", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            if !group.expenses.isEmpty {
                Button {
                    isAddingExpense = true
                } label: {
                    Label("Add Expense", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 54)
                        .background(Capsule().fill(Brand.gradient))
                        .shadow(color: Brand.primary.opacity(0.4), radius: 10, y: 5)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.trailing, 20)
                .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $isAddingExpense) {
            GroupExpenseSheet(group: group, existing: nil) { store.upsert($0, in: groupID) }
        }
        .sheet(item: $editingExpense) { expense in
            GroupExpenseSheet(group: group, existing: expense) { store.upsert($0, in: groupID) }
        }
        .sheet(isPresented: $isSettlingUp) {
            SettleUpView(groupID: groupID)
                .environmentObject(store)
                .environmentObject(profileStore)
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $isEditingGroup) {
            GroupFormSheet(existing: group) { store.save($0) }
        }
        .confirmationDialog("Delete \"\(group.name)\"?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete Group", role: .destructive) {
                store.delete(group)
                dismiss()
            }
        } message: {
            Text("All of its expenses will be deleted. This can't be undone.")
        }
    }

    // MARK: - Pieces

    private func summaryCard(_ group: ExpenseGroup, _ ledger: GroupLedger) -> some View {
        let myBalance = ledger.balance(of: GroupMember.meID)

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(group.emoji)
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.title3.weight(.bold))
                    Text(group.members.map(\.name).joined(separator: ", "))
                        .font(.caption)
                        .opacity(0.85)
                        .lineLimit(2)
                }
            }

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total spent")
                        .font(.caption)
                        .opacity(0.85)
                    Text(Currency.string(ledger.totalSpent))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Your share")
                        .font(.caption)
                        .opacity(0.85)
                    Text(Currency.string(ledger.share(of: GroupMember.meID)))
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            if !group.expenses.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: abs(myBalance) < 0.01 ? "checkmark.seal.fill"
                          : myBalance > 0 ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    Text(abs(myBalance) < 0.01 ? "You're all settled up"
                         : myBalance > 0 ? "You get back \(Currency.string(myBalance))"
                         : "You owe \(Currency.string(-myBalance))")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if !ledger.isSettled {
                    Button {
                        isSettlingUp = true
                    } label: {
                        Label("Settle Up", systemImage: "arrow.left.arrow.right")
                            .font(.headline)
                            .foregroundStyle(Brand.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Brand.gradient))
    }

    private func memberBalanceRow(_ member: GroupMember, _ ledger: GroupLedger) -> some View {
        let balance = ledger.balance(of: member.id)
        return HStack(spacing: 12) {
            MemberAvatar(member: member)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name)
                    .font(.body.weight(.medium))
                Text("Paid \(Currency.string(ledger.paid[member.id] ?? 0)) · Share \(Currency.string(ledger.share(of: member.id)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if abs(balance) < 0.01 {
                Text("settled")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(balance > 0 ? "gets back" : "owes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(Currency.string(abs(balance)))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(balance > 0 ? Color.green : Color.orange)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func expenseRow(_ expense: GroupExpense, in group: ExpenseGroup) -> some View {
        let people = group.participants(of: expense).count
        let split = people == group.members.count ? "split equally" : "split \(people) ways"

        return HStack(spacing: 12) {
            Image(systemName: expense.category.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(expense.category.color.gradient))
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text("\(group.name(of: expense.paidBy)) paid · \(split) · \(expense.date.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Currency.string(expense.amount))
                .font(.callout.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

struct MemberAvatar: View {
    let member: GroupMember
    var size: CGFloat = 36

    private static let palette: [Color] = [.orange, .blue, .purple, .pink, .teal, .indigo, .green, .red]

    private var color: Color {
        if member.isMe { return Brand.primary }
        let hash = member.id.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF }
        return Self.palette[hash % Self.palette.count]
    }

    var body: some View {
        Text(member.isMe ? "You" : String(member.name.prefix(1)).uppercased())
            .font(.system(size: member.isMe ? size * 0.3 : size * 0.42, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color.gradient))
            .accessibilityHidden(true)
    }
}

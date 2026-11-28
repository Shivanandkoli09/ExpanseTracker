//
//  GroupsListView.swift
//  ExpanseTracker
//

import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject private var store: GroupsStore
    @State private var isCreating = false
    @State private var groupPendingDelete: ExpenseGroup?

    var body: some View {
        List {
            if store.groups.isEmpty {
                ContentUnavailableView {
                    Label("No groups yet", systemImage: "person.3")
                } description: {
                    Text("Create a group for a trip, flat or dinner. Log who paid, and we'll work out who owes whom.")
                } actions: {
                    Button("Create Group") { isCreating = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Brand.primary)
                }
                .listRowBackground(Color.clear)
            }

            ForEach(store.groups) { group in
                NavigationLink(value: AppRoute.group(id: group.id)) {
                    GroupRow(group: group)
                }
                .swipeActions {
                    Button(role: .destructive) {
                        groupPendingDelete = group
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Groups")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isCreating = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New group")
            }
        }
        .sheet(isPresented: $isCreating) {
            GroupFormSheet(existing: nil) { store.save($0) }
        }
        .confirmationDialog(
            "Delete \"\(groupPendingDelete?.name ?? "")\"?",
            isPresented: Binding(get: { groupPendingDelete != nil }, set: { if !$0 { groupPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Delete Group", role: .destructive) {
                if let group = groupPendingDelete { store.delete(group) }
            }
        } message: {
            Text("All of its expenses will be deleted. This can't be undone.")
        }
    }
}

struct GroupRow: View {
    let group: ExpenseGroup

    var body: some View {
        let ledger = GroupLedger(group: group)
        let balance = ledger.balance(of: GroupMember.meID)

        HStack(spacing: 12) {
            Text(group.emoji)
                .font(.title2)
                .frame(width: 46, height: 46)
                .background(Brand.primary.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(group.members.count) people · \(Currency.string(ledger.totalSpent))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            BalanceLabel(balance: balance, settledText: group.expenses.isEmpty ? "No expenses" : "Settled")
        }
        .padding(.vertical, 4)
    }
}

/// "you get ₹X" / "you owe ₹X" / "Settled", used for the signed-in user.
struct BalanceLabel: View {
    let balance: Double
    var settledText = "Settled"

    var body: some View {
        VStack(alignment: .trailing, spacing: 1) {
            if abs(balance) < 0.01 {
                Text(settledText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            } else {
                Text(balance > 0 ? "you get" : "you owe")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(Currency.string(abs(balance)))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(balance > 0 ? Color.green : Color.orange)
            }
        }
    }
}

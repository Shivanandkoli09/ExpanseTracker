//
//  TransactionRowView.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 18/06/25.
//

import SwiftUI

struct TransactionRowView: View {
    let txn: Transaction
    /// Set for your share of a group expense.
    var groupName: String? = nil

    private var isIncome: Bool { txn.type == .income }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: txn.category.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(Circle().fill(txn.category.color.gradient))

            VStack(alignment: .leading, spacing: 3) {
                Text(txn.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let groupName {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                        Text("\(groupName) · your share · \(txn.date.formatted(.dateTime.day().month(.abbreviated)))")
                    }
                    .font(.caption)
                    .foregroundStyle(Brand.primary)
                    .lineLimit(1)
                } else {
                    Text("\(txn.category.displayName) · \(txn.date.formatted(.dateTime.day().month(.abbreviated)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text((isIncome ? "+" : "−") + Currency.string(txn.amount))
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(isIncome ? Color.green : Color.primary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        TransactionRowView(txn: Transaction(title: "Swiggy dinner", amount: 450, date: Date(), type: .expense, category: .food))
        TransactionRowView(txn: Transaction(title: "Salary", amount: 85000, date: Date(), type: .income, category: .salary))
    }
}

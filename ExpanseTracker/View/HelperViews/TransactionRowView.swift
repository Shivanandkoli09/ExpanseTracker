//
//  TransactionRowView.swift
//  ExpanseTracker
//
//  Created by KPIT on 18/06/25.
//

import SwiftUI

struct TransactionRowView: View {
    let txn: Transaction

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Top Row
            HStack {
                Text(txn.title)
                    .font(.headline)

                Spacer()

                Text("₹\(txn.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(txn.type == .income ? .green : .red)
            }

            // Bottom Row
            HStack(spacing: 8) {

                // ✅ Type Badge
                Text(txn.type.rawValue)
                    .font(.caption)
                    .padding(6)
                    .background(txn.type == .income ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .foregroundColor(txn.type == .income ? .green : .red)
                    .cornerRadius(6)

                // ✅ NEW: Category Badge (AI Powered)
                Text(txn.category.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForCategory(txn.category).opacity(0.15))
                    .foregroundColor(colorForCategory(txn.category))
                    .cornerRadius(6)

                Spacer()

                Text(txn.date, format: .dateTime.day().month().year())
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    // ✅ Helper for dynamic colors
    private func colorForCategory(_ category: TransactionCategory) -> Color {
        switch category {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .purple
        case .bills: return .red
        case .entertainment: return .pink
        case .salary: return .green
        case .other: return .gray
        }
    }
}

#Preview {
    TransactionRowView(txn: Transaction(titile: "Sample Income", amount: 1200, date: Date(), type: .income))
}

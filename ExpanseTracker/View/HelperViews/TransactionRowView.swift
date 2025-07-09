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
               VStack(alignment: .leading, spacing: 4) {
                   HStack {
                       Text(txn.title)
                           .font(.headline)
                       Spacer()
                       Text("₹\(txn.amount, specifier: "%.2f")")
                           .font(.subheadline)
                           .foregroundColor(txn.type == .income ? .green : .red)
                   }

                   HStack {
                       Text(txn.type.rawValue)
                           .font(.caption)
                           .padding(6)
                           .background(txn.type == .income ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                           .cornerRadius(6)

                       Spacer()

                       Text(txn.date, format: .dateTime.day().month().year())
                           .font(.caption2)
                           .foregroundColor(.gray)
                   }
               }
               .padding(8)
               .background(Color(.secondarySystemBackground))
               .cornerRadius(10)
           }
}

#Preview {
    TransactionRowView(txn: Transaction(titile: "Sample Income", amount: 1200, date: Date(), type: .income))
}

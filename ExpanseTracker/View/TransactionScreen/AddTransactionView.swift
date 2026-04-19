//
//  AddTransactionView.swift
//  ExpanseTracker
//
//  Created by KPIT on 10/06/25.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var manager: TransactionManager
    @EnvironmentObject var firestoreManager: FirestoreTransactionManager
    
    var existingTransaction: Transaction?

    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var type: TransactionType

    init(manager: TransactionManager, existingTransaction: Transaction? = nil) {
        self.manager = manager
        self.existingTransaction = existingTransaction

        if let txn = existingTransaction {
            _title = State(initialValue: txn.title)
            _amount = State(initialValue: "\(txn.amount)")
            _date = State(initialValue: txn.date)
            _type = State(initialValue: txn.type)
        } else {
            _title = State(initialValue: "")
            _amount = State(initialValue: "")
            _date = State(initialValue: Date())
            _type = State(initialValue: .expanse)
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack {
                Form {
                    Section(header: Text("Details").foregroundColor(.secondary)) {
                        TextField("Title", text: $title)
                            .textInputAutocapitalization(.words)
                            .padding(.vertical, 4)

                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 4)

                        Picker("Type", selection: $type) {
                            ForEach(TransactionType.allCases) { t in
                                Text(t.rawValue.capitalized).tag(t)
                            }
                        }

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    }

                    Section {
                        Button(action: {
                            let amt = Double(amount) ?? 0
                            if let existing = existingTransaction {
                                let updatedTxn = Transaction(
                                    id: existing.id,
                                    titile: title,
                                    amount: amt,
                                    date: date,
                                    type: type
                                )

                                manager.updateTransaction(updatedTxn)

                                Task {
                                    try? await firestoreManager.updateTransaction(updatedTxn)
                                }
                            } else {
                                let txn = Transaction(
                                    id: UUID().uuidString,
                                    titile: title,
                                    amount: amt,
                                    date: date,
                                    type: type
                                )

                                // Add to Core Data
                                manager.addTransaction(
                                    title: txn.title,
                                    amount: txn.amount,
                                    date: txn.date,
                                    type: txn.type
                                )

                            }

                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text(existingTransaction == nil ? "Add Transaction" : "Update Transaction")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(title.isEmpty || amount.isEmpty)
                    }
                }
                .modifier(KeyboardDismissModifier())
                .navigationTitle(existingTransaction == nil ? "Add Transaction" : "Edit Transaction")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    return AddTransactionView(manager: TransactionManager(context: context))
}

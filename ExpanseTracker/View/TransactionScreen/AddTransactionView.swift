//
//  AddTransactionView.swift
//  ExpanseTracker
//
//  Created by KPIT on 10/06/25.
//

import SwiftUI

struct AddTransactionView: View {
//    @EnvironmentObject  var transactionManager: TransactionManager
//    @Binding var transactions: [Transaction]
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var manager: TransactionManager
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
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
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
                    
                    // ✅ Action Button inside the form
                    Section {
                        Button(action: {
                            let amt = Double(amount) ?? 0
                            if let existing = existingTransaction {
                                let updated = Transaction(id: existing.id, titile: title, amount: amt, date: date, type: type)
                                manager.updateTransaction(updated)
                            } else {
                                manager.addTransaction(title: title, amount: amt, date: date, type: type)
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

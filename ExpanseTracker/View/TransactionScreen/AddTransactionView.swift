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
            _title = State(initialValue: txn.titile)
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
        Form {
            TextField("Title", text: $title)
            TextField("Amount", text: $amount)
                .keyboardType(.decimalPad)
            Picker("Type", selection: $type) {
                ForEach(TransactionType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            DatePicker("Date", selection: $date, displayedComponents: .date)
            
//            Button(existingTransaction == nil ? "Add Transaction" : "Update Transaction") {
//                let amt = Double(amount) ?? 0
//                if let existing = existingTransaction {
//                    // Edit mode: remove old, add updated
//                    manager.transactions.removeAll { $0.id == existing.id }
//                }
//                let newTxn = Transaction(titile: title, amount: amt, date: date, type: type)
//                manager.transactions.append(newTxn)
//                dismiss()
//            }
//            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(existingTransaction == nil ? "Add Transaction" : "Edit Transaction")
        
        
        Button(existingTransaction == nil ? "Add Transaction" : "Update Transaction") {
            let amt = Double(amount) ?? 0
            if let existing = existingTransaction {
                // Edit mode: remove old, add updated
                manager.transactions.removeAll { $0.id == existing.id }
            }
            let newTxn = Transaction(titile: title, amount: amt, date: date, type: type)
            manager.transactions.append(newTxn)
            dismiss()
        }
        .disabled(title.isEmpty || amount.isEmpty)

//        Button("Add Transaction") {
//            if let amt = Double(amount) {
//                let newTxn = Transaction(titile: title, amount: amt, date: date, type: type)
//                transactionManager.transactions.append(newTxn)
//                dismiss()
//            }
//        }
//        .disabled(title.isEmpty || amount.isEmpty)
    }
}

#Preview {
    AddTransactionView(manager: TransactionManager())
}

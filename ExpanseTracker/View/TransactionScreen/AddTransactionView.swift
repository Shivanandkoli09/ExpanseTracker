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
    
    @State private var suggestedType: TransactionType = .expanse
    @State private var suggestedCategory: TransactionCategory = .other
    
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
                        
                        // ✅ Title Field with AI detection
                        TextField("Title", text: $title)
                            .textInputAutocapitalization(.words)
                            .padding(.vertical, 4)
                            .onChange(of: title) { newValue in
                                let prediction = AITransactionClassifier.shared.predict(title: newValue)
                                suggestedType = prediction.type
                                suggestedCategory = prediction.category

                                // Auto update type
                                type = prediction.type
                            }

                        // ✅ AI Suggestion UI
                        if !title.isEmpty {
                            HStack {
                                Text("AI Suggestion:")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Text(suggestedCategory.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.blue)

                                Text("• \(suggestedType.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }

                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 4)
                        
                        Picker("Category", selection: $suggestedCategory) {
                            ForEach(TransactionCategory.allCases, id: \.self) { category in
                                Text(category.rawValue.capitalized).tag(category)
                            }
                        }

                        Picker("Type", selection: $type) {
                            ForEach(TransactionType.allCases) { t in
                                Text(t.rawValue.capitalized).tag(t)
                            }
                        }

                        DatePicker("Date", selection: $date, displayedComponents: .date)
                    }

                    Section {
                        Button(action: {
                            // Save user correction
                            let prediction = AITransactionClassifier.shared.predict(title: title)

                            // Save ONLY if user changed AI suggestion
                            let words = title.lowercased().split(separator: " ")

                            if let firstWord = words.first {
                                UserPreferenceStore.shared.savePreference(
                                    keyword: String(firstWord),
                                    category: suggestedCategory
                                )
                            }
                            let amt = Double(amount) ?? 0
                            if let existing = existingTransaction {
                                let updatedTxn = Transaction(
                                    id: existing.id,
                                    titile: title,
                                    amount: amt,
                                    date: date,
                                    type: type,
                                    category: suggestedCategory   // ✅ AI category
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
                                    type: type,
                                    category: suggestedCategory   // ✅ AI category
                                )

                                // Add to Core Data
                                manager.addTransaction(
                                    title: txn.title,
                                    amount: txn.amount,
                                    date: txn.date,
                                    type: txn.type,
                                    category: txn.category
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

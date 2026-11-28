//
//  AddTransactionView.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 10/06/25.
//

import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var manager: TransactionManager
    let existingTransaction: Transaction?

    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var type: TransactionType
    @State private var category: TransactionCategory

    /// Once the user picks a value themselves, AI suggestions stop overwriting it.
    @State private var userChoseCategory: Bool
    @State private var userChoseType: Bool

    @FocusState private var focusedField: FieldFocus?

    init(manager: TransactionManager, existingTransaction: Transaction? = nil) {
        self.manager = manager
        self.existingTransaction = existingTransaction

        let txn = existingTransaction
        _title = State(initialValue: txn?.title ?? "")
        _amount = State(initialValue: txn.map { Self.amountString($0.amount) } ?? "")
        _date = State(initialValue: txn?.date ?? Date())
        _type = State(initialValue: txn?.type ?? .expense)
        _category = State(initialValue: txn?.category ?? .other)
        _userChoseCategory = State(initialValue: txn != nil)
        _userChoseType = State(initialValue: txn != nil)
    }

    private var isEditing: Bool { existingTransaction != nil }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedAmount: Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let value = formatter.number(from: amount)?.doubleValue ?? Double(amount)
        guard let value, value > 0 else { return nil }
        return value
    }

    private var canSave: Bool { !trimmedTitle.isEmpty && parsedAmount != nil }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title (e.g. Swiggy dinner)", text: $title)
                    .textInputAutocapitalization(.words)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .amount }
                    .onChange(of: title) { _, newValue in
                        applySuggestion(for: newValue)
                    }

                if !trimmedTitle.isEmpty && !userChoseCategory {
                    Label {
                        Text("Auto-categorised as **\(category.rawValue.capitalized)** · \(type.rawValue)")
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)

                Picker("Category", selection: Binding(
                    get: { category },
                    set: { category = $0; userChoseCategory = true }
                )) {
                    ForEach(TransactionCategory.allCases, id: \.self) { category in
                        Text(category.rawValue.capitalized).tag(category)
                    }
                }

                Picker("Type", selection: Binding(
                    get: { type },
                    set: { type = $0; userChoseType = true }
                )) {
                    ForEach(TransactionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                DatePicker("Date", selection: $date, displayedComponents: .date)
            }

            Section {
                Button(action: save) {
                    Text(isEditing ? "Update Transaction" : "Add Transaction")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .disabled(!canSave)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(isEditing ? "Edit Transaction" : "Add Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onAppear {
            if !isEditing { focusedField = .title }
        }
    }

    // MARK: - Actions

    private func applySuggestion(for title: String) {
        let prediction = AITransactionClassifier.shared.predict(title: title)
        if !userChoseCategory { category = prediction.category }
        if !userChoseType { type = prediction.type }
    }

    private func save() {
        guard let value = parsedAmount, !trimmedTitle.isEmpty else { return }

        // Learn only from real corrections, keyed on the most meaningful word.
        let prediction = AITransactionClassifier.shared.predict(title: trimmedTitle)
        if userChoseCategory,
           category != prediction.category,
           let keyword = AITransactionClassifier.keyword(in: trimmedTitle) {
            UserPreferenceStore.shared.savePreference(keyword: keyword, category: category)
        }

        let txn = Transaction(
            id: existingTransaction?.id ?? UUID().uuidString,
            title: trimmedTitle,
            amount: value,
            date: date,
            type: type,
            category: category
        )

        if isEditing {
            manager.update(txn)
        } else {
            manager.add(txn)
        }
        dismiss()
    }

    private static func amountString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

#Preview {
    NavigationStack {
        AddTransactionView(manager: TransactionManager(context: PersistenceController(inMemory: true).container.viewContext))
    }
}

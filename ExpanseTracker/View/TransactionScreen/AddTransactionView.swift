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
    /// Lets the presenter offer "Undo" after a delete.
    var onDelete: ((Transaction) -> Void)?

    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var type: TransactionType
    @State private var category: TransactionCategory

    /// Once the user picks a value themselves, AI suggestions stop overwriting it.
    @State private var userChoseCategory: Bool
    @State private var userChoseType: Bool
    @State private var isConfirmingDelete = false

    @FocusState private var focusedField: FieldFocus?

    init(manager: TransactionManager,
         existingTransaction: Transaction? = nil,
         onDelete: ((Transaction) -> Void)? = nil) {
        self.manager = manager
        self.existingTransaction = existingTransaction
        self.onDelete = onDelete

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

    private var accent: Color { type == .income ? .green : Brand.primary }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                typePicker
                amountField
                titleField
                categoryGrid
                dateSection

                PrimaryButton(
                    title: isEditing ? "Save Changes" : "Add \(type.rawValue)",
                    isEnabled: canSave,
                    action: save
                )
                .padding(.top, 4)

                if isEditing {
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("Delete Transaction", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                    }
                    .tint(.red)
                }
            }
            .padding(20)
            .animation(.spring(duration: 0.3), value: type)
            .animation(.spring(duration: 0.3), value: category)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? "Edit Transaction" : "New Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .confirmationDialog("Delete this transaction?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive, action: delete)
        }
        .onAppear {
            if !isEditing { focusedField = .amount }
        }
    }

    // MARK: - Sections

    private var typePicker: some View {
        HStack(spacing: 4) {
            ForEach([TransactionType.expense, .income]) { option in
                Button {
                    type = option
                    userChoseType = true
                } label: {
                    Label(option.rawValue, systemImage: option == .expense ? "arrow.up.right" : "arrow.down.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .foregroundStyle(type == option ? .white : .secondary)
                        .background {
                            if type == option {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(option == .income ? Color.green : Brand.primary)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(type == option ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .sensoryFeedback(.selection, trigger: type)
    }

    private var amountField: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(amount.isEmpty ? .tertiary : .secondary)
                TextField("0", text: $amount)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .fixedSize()
                    .foregroundStyle(accent)
            }
            Text(type == .income ? "Money in" : "Money out")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture { focusedField = .amount }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "text.cursor")
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                TextField("What was it for? e.g. Swiggy dinner", text: $title)
                    .textInputAutocapitalization(.sentences)
                    .focused($focusedField, equals: .title)
                    .submitLabel(.done)
                    .onChange(of: title) { _, newValue in
                        applySuggestion(for: newValue)
                    }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !trimmedTitle.isEmpty && !userChoseCategory {
                Label("Auto-categorised as \(category.displayName)", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Brand.primary)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Category")
                .font(.subheadline.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(TransactionCategory.allCases, id: \.self) { option in
                    categoryChip(option)
                }
            }
        }
        .sensoryFeedback(.selection, trigger: category)
    }

    private func categoryChip(_ option: TransactionCategory) -> some View {
        let isSelected = category == option
        return Button {
            category = option
            userChoseCategory = true
            if !userChoseType { type = option.defaultType }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : option.color)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(isSelected ? AnyShapeStyle(option.color.gradient) : AnyShapeStyle(option.color.opacity(0.15))))
                Text(option.displayName)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? option.color : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(option.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var dateSection: some View {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        return HStack(spacing: 8) {
            dateChip("Today", isSelected: calendar.isDateInToday(date)) { date = Date() }
            dateChip("Yesterday", isSelected: calendar.isDateInYesterday(date)) { date = yesterday }
            Spacer(minLength: 0)
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .labelsHidden()
        }
    }

    private func dateChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(
                    Capsule().fill(isSelected ? AnyShapeStyle(accent) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                )
        }
        .buttonStyle(.plain)
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
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }

    private func delete() {
        guard let existingTransaction else { return }
        if let onDelete {
            onDelete(existingTransaction)
        } else {
            manager.delete(existingTransaction)
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

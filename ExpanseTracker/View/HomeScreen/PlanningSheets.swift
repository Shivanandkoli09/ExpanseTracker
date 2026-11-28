//
//  PlanningSheets.swift
//  ExpanseTracker
//
//  Sheets for setting a monthly budget and a saving goal.
//

import SwiftUI

// MARK: - Amount Field

private struct RupeeAmountField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 6) {
            Text("₹")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .font(.title2.weight(.semibold))
                .keyboardType(.numberPad)
                .focused(focused)
                .onChange(of: text) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits != newValue { text = digits }
                }
        }
    }
}

private struct PresetChips: View {
    let presets: [Double]
    let onPick: (Double) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { value in
                    Button(Currency.compact(value)) { onPick(value) }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.tertiarySystemFill), in: Capsule())
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

private func amount(from text: String) -> Double? {
    guard let value = Double(text), value > 0 else { return nil }
    return value
}

private func text(from amount: Double?) -> String {
    amount.map { String(Int($0)) } ?? ""
}

// MARK: - Budget

struct BudgetSheet: View {
    let currentBudget: Double?
    let averageSpend: Double
    let onSave: (Double?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String
    @FocusState private var isFocused: Bool

    init(currentBudget: Double?, averageSpend: Double, onSave: @escaping (Double?) -> Void) {
        self.currentBudget = currentBudget
        self.averageSpend = averageSpend
        self.onSave = onSave
        _amountText = State(initialValue: text(from: currentBudget))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    RupeeAmountField(placeholder: "Monthly budget", text: $amountText, focused: $isFocused)
                    PresetChips(presets: [5_000, 10_000, 20_000, 30_000, 50_000]) {
                        amountText = text(from: $0)
                    }
                } footer: {
                    if averageSpend > 0 {
                        Text("You've spent about \(Currency.string(averageSpend.rounded())) a month lately. We'll show how much you can safely spend each day.")
                    } else {
                        Text("We'll show how much you can safely spend each day to stay on track.")
                    }
                }

                if currentBudget != nil {
                    Section {
                        Button("Remove Budget", role: .destructive) {
                            onSave(nil)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Monthly Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(amount(from: amountText))
                        dismiss()
                    }
                    .disabled(amount(from: amountText) == nil)
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Saving Goal

struct GoalSheet: View {
    let onSave: (SavingGoal?, Double?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var goal: SavingGoal?
    @State private var targetText: String
    @FocusState private var isFocused: Bool

    init(goal: SavingGoal?, target: Double?, onSave: @escaping (SavingGoal?, Double?) -> Void) {
        self.onSave = onSave
        _goal = State(initialValue: goal)
        _targetText = State(initialValue: text(from: target))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What are you saving for?") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(SavingGoal.allCases) { option in
                            GoalChip(goal: option, isSelected: goal == option) {
                                goal = option
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .sensoryFeedback(.selection, trigger: goal)
                }

                if goal != nil {
                    Section {
                        RupeeAmountField(placeholder: "Target amount", text: $targetText, focused: $isFocused)
                        PresetChips(presets: [25_000, 50_000, 1_00_000, 2_00_000, 5_00_000]) {
                            targetText = text(from: $0)
                        }
                    } header: {
                        Text("Target")
                    } footer: {
                        Text("Progress counts everything you've earned minus everything you've spent in MyMoney.")
                    }
                }
            }
            .navigationTitle("Saving Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(goal, amount(from: targetText))
                        dismiss()
                    }
                    .disabled(goal == nil)
                }
            }
            .animation(.default, value: goal)
        }
        .presentationDetents([.large])
    }
}

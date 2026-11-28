//
//  GroupForms.swift
//  ExpanseTracker
//

import SwiftUI

// MARK: - Create / Edit Group

struct GroupFormSheet: View {
    let existing: ExpenseGroup?
    let onSave: (ExpenseGroup) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var emoji: String
    @State private var members: [GroupMember]
    @State private var newMemberName = ""
    @FocusState private var focus: Field?

    private enum Field { case name, member }

    private static let emojis = ["🏖️", "✈️", "🏔️", "🚗", "🏠", "🍽️", "🎉", "🎓", "⚽️", "🛒"]

    init(existing: ExpenseGroup?, onSave: @escaping (ExpenseGroup) -> Void) {
        self.existing = existing
        self.onSave = onSave
        _name = State(initialValue: existing?.name ?? "")
        _emoji = State(initialValue: existing?.emoji ?? "🏖️")
        _members = State(initialValue: existing?.members ?? [.me])
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedMember: String { newMemberName.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty && members.count >= 2 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Goa Trip", text: $name)
                        .textInputAutocapitalization(.words)
                        .focused($focus, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focus = .member }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Self.emojis, id: \.self) { option in
                                Button {
                                    emoji = option
                                } label: {
                                    Text(option)
                                        .font(.title2)
                                        .frame(width: 46, height: 46)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(emoji == option ? Brand.primary.opacity(0.15) : Color(.tertiarySystemFill))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(emoji == option ? Brand.primary : .clear, lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Group name")
                }

                Section {
                    ForEach(members) { member in
                        HStack(spacing: 12) {
                            MemberAvatar(member: member, size: 30)
                            Text(member.isMe ? "You" : member.name)
                            Spacer()
                            if !member.isMe {
                                if existing?.isInvolved(member.id) == true {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .accessibilityLabel("Has expenses, can't be removed")
                                } else {
                                    Button {
                                        members.removeAll { $0.id == member.id }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(.red)
                                    }
                                    .buttonStyle(.borderless)
                                    .accessibilityLabel("Remove \(member.name)")
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .foregroundStyle(Brand.primary)
                            .frame(width: 30)
                        TextField("Add a person", text: $newMemberName)
                            .textInputAutocapitalization(.words)
                            .focused($focus, equals: .member)
                            .submitLabel(.done)
                            .onSubmit(addMember)
                        if !trimmedMember.isEmpty {
                            Button("Add", action: addMember)
                                .buttonStyle(.borderless)
                                .fontWeight(.semibold)
                        }
                    }
                } header: {
                    Text("People (\(members.count))")
                } footer: {
                    Text("Only names are needed. Friends don't need the app.")
                }
            }
            .navigationTitle(existing == nil ? "New Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Create" : "Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if existing == nil { focus = .name }
            }
        }
    }

    private func addMember() {
        let name = trimmedMember
        guard !name.isEmpty else { return }
        let isDuplicate = members.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
            || name.caseInsensitiveCompare("you") == .orderedSame
        if !isDuplicate {
            members.append(GroupMember(id: UUID().uuidString, name: name))
        }
        newMemberName = ""
        focus = .member
    }

    private func save() {
        // A name typed but not yet "added" shouldn't be lost.
        if !trimmedMember.isEmpty { addMember() }
        var group = existing ?? ExpenseGroup(name: trimmedName, emoji: emoji, members: members)
        group.name = trimmedName
        group.emoji = emoji
        group.members = members
        onSave(group)
        dismiss()
    }
}

// MARK: - Add / Edit Group Expense

struct GroupExpenseSheet: View {
    let group: ExpenseGroup
    let existing: GroupExpense?
    let onSave: (GroupExpense) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var amount: String
    @State private var paidBy: String
    @State private var splitAmong: Set<String>
    @State private var date: Date
    @State private var category: TransactionCategory
    @State private var userChoseCategory: Bool
    @FocusState private var focusedField: FieldFocus?

    init(group: ExpenseGroup, existing: GroupExpense?, onSave: @escaping (GroupExpense) -> Void) {
        self.group = group
        self.existing = existing
        self.onSave = onSave
        _title = State(initialValue: existing?.title ?? "")
        _amount = State(initialValue: existing.map { String(format: $0.amount.rounded() == $0.amount ? "%.0f" : "%.2f", $0.amount) } ?? "")
        _paidBy = State(initialValue: existing?.paidBy ?? GroupMember.meID)
        _splitAmong = State(initialValue: Set(existing.map { group.participants(of: $0) } ?? group.members.map(\.id)))
        _date = State(initialValue: existing?.date ?? Date())
        _category = State(initialValue: existing?.category ?? .other)
        _userChoseCategory = State(initialValue: existing != nil)
    }

    private var parsedAmount: Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let value = formatter.number(from: amount)?.doubleValue ?? Double(amount)
        guard let value, value > 0 else { return nil }
        return value
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty && parsedAmount != nil && !splitAmong.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("₹")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        TextField("0", text: $amount)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                    }
                    HStack {
                        TextField("What was it for? e.g. Hotel", text: $title)
                            .textInputAutocapitalization(.sentences)
                            .focused($focusedField, equals: .title)
                            .onChange(of: title) { _, newValue in
                                if !userChoseCategory {
                                    category = AITransactionClassifier.shared.predict(title: newValue).category
                                }
                            }
                        Menu {
                            Picker("Category", selection: Binding(
                                get: { category },
                                set: { category = $0; userChoseCategory = true }
                            )) {
                                ForEach(TransactionCategory.allCases, id: \.self) { option in
                                    Label(option.displayName, systemImage: option.icon).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: category.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(category.color.gradient))
                        }
                        .accessibilityLabel("Category: \(category.displayName)")
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Paid by") {
                    memberChips(selected: { paidBy == $0 }) { paidBy = $0 }
                }

                Section {
                    memberChips(selected: { splitAmong.contains($0) }) { id in
                        if splitAmong.contains(id) { splitAmong.remove(id) } else { splitAmong.insert(id) }
                    }
                } header: {
                    HStack {
                        Text("Split between")
                        Spacer()
                        Button(splitAmong.count == group.members.count ? "Clear" : "Everyone") {
                            splitAmong = splitAmong.count == group.members.count ? [] : Set(group.members.map(\.id))
                        }
                        .font(.caption.weight(.semibold))
                        .textCase(nil)
                    }
                } footer: {
                    if let value = parsedAmount, !splitAmong.isEmpty {
                        Text("\(Currency.string((value / Double(splitAmong.count) * 100).rounded() / 100)) each · \(splitAmong.count) \(splitAmong.count == 1 ? "person" : "people")")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Brand.primary)
                    } else if splitAmong.isEmpty {
                        Text("Pick at least one person.")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(existing == nil ? "Add Expense" : "Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .sensoryFeedback(.selection, trigger: paidBy)
            .onAppear {
                if existing == nil { focusedField = .amount }
            }
        }
    }

    private func memberChips(selected: @escaping (String) -> Bool, onTap: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(group.members) { member in
                    let isSelected = selected(member.id)
                    Button {
                        onTap(member.id)
                    } label: {
                        VStack(spacing: 6) {
                            MemberAvatar(member: member, size: 44)
                                .overlay(
                                    Circle().stroke(isSelected ? Brand.primary : .clear, lineWidth: 3)
                                        .padding(-4)
                                )
                                .overlay(alignment: .bottomTrailing) {
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white, Brand.primary)
                                            .offset(x: 4, y: 4)
                                    }
                                }
                                .opacity(isSelected ? 1 : 0.45)
                            Text(member.isMe ? "You" : member.name)
                                .font(.caption)
                                .lineLimit(1)
                                .frame(maxWidth: 64)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(member.name)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .scrollClipDisabled()
    }

    private func save() {
        guard let value = parsedAmount, !splitAmong.isEmpty else { return }
        // Always store exactly who shared it, so people added to the group later
        // don't change old expenses.
        let expense = GroupExpense(
            id: existing?.id ?? UUID().uuidString,
            title: trimmedTitle,
            amount: value,
            paidBy: paidBy,
            splitAmong: group.members.map(\.id).filter(splitAmong.contains),
            date: date,
            category: category
        )
        onSave(expense)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

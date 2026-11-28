//
//  GroupsEntryCard.swift
//  ExpanseTracker
//

import SwiftUI

/// Home screen entry point to shared group expenses.
struct GroupsEntryCard: View {
    let groups: [ExpenseGroup]
    let onOpen: () -> Void

    var body: some View {
        let balances = groups.map { GroupLedger(group: $0).balance(of: GroupMember.meID) }
        let owedToMe = balances.filter { $0 > 0 }.reduce(0, +)
        let iOwe = -balances.filter { $0 < 0 }.reduce(0, +)

        Button(action: onOpen) {
            HStack(spacing: 14) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.gradient))

                VStack(alignment: .leading, spacing: 3) {
                    Text(groups.isEmpty ? "Split with friends" : "Groups & trips")
                        .font(.headline)
                    Text(subtitle(owedToMe: owedToMe, iOwe: iOwe))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func subtitle(owedToMe: Double, iOwe: Double) -> String {
        if groups.isEmpty {
            return "Log trip expenses and see who owes whom."
        }
        var parts: [String] = []
        if owedToMe >= 0.01 { parts.append("You get \(Currency.string(owedToMe))") }
        if iOwe >= 0.01 { parts.append("you owe \(Currency.string(iOwe))") }
        if parts.isEmpty {
            return "\(groups.count) \(groups.count == 1 ? "group" : "groups") · all settled"
        }
        return parts.joined(separator: " · ")
    }
}

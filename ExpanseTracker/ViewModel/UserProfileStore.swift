//
//  UserProfileStore.swift
//  ExpanseTracker
//
//  Live copy of users/{uid}: saving goal, goal target and monthly budget.
//  Shared by Home and Profile so both always show the same values.
//

import Foundation
import FirebaseFirestore

@MainActor
final class UserProfileStore: ObservableObject {

    @Published private(set) var savingGoal: SavingGoal?
    @Published private(set) var goalTarget: Double?
    @Published private(set) var monthlyBudget: Double?
    /// The user's UPI ID for receiving money (e.g. name@okhdfcbank).
    @Published private(set) var upiID: String?

    private let document: DocumentReference
    private let listener = ListenerBox()

    init(userId: String) {
        document = FirestoreTransactionManager.profileDocument(for: userId)
        listener.registration = document.addSnapshotListener { [weak self] snapshot, _ in
            guard let data = snapshot?.data() else { return }
            let goal = (data["savingGoal"] as? String).flatMap(SavingGoal.init(rawValue:))
            let target = (data["savingGoalTarget"] as? NSNumber)?.doubleValue
            let budget = (data["monthlyBudget"] as? NSNumber)?.doubleValue
            let upi = data["upiId"] as? String
            Task { @MainActor in
                self?.upiID = upi
                self?.savingGoal = goal
                self?.goalTarget = target
                self?.monthlyBudget = budget
            }
        }
    }

    // Writes update the UI immediately; Firestore syncs in the background (works offline).

    func setSavingGoal(_ goal: SavingGoal?, target: Double?) {
        savingGoal = goal
        goalTarget = goal == nil ? nil : target
        write([
            "savingGoal": goal?.rawValue ?? FieldValue.delete(),
            "savingGoalTarget": goalTarget ?? FieldValue.delete()
        ])
    }

    func setMonthlyBudget(_ amount: Double?) {
        monthlyBudget = amount
        write(["monthlyBudget": amount ?? FieldValue.delete()])
    }

    func setUPIID(_ id: String?) {
        let trimmed = id?.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = (trimmed?.isEmpty ?? true) ? nil : trimmed
        upiID = value
        write(["upiId": value ?? FieldValue.delete()])
    }

    private func write(_ fields: [String: Any]) {
        document.setData(fields, merge: true) { error in
            if let error { print("☁️ Profile update failed: \(error.localizedDescription)") }
        }
    }
}

/// Removes the Firestore listener when the store goes away.
private final class ListenerBox {
    var registration: ListenerRegistration?
    deinit { registration?.remove() }
}

//
//  GroupsStore.swift
//  ExpanseTracker
//
//  Live list of the user's groups. Writes update the UI immediately and
//  sync to Firestore in the background (works offline).
//

import Foundation
import FirebaseFirestore

@MainActor
final class GroupsStore: ObservableObject {

    @Published private(set) var groups: [ExpenseGroup] = []
    /// False until a trustworthy snapshot arrives. An empty *cached* snapshot
    /// (e.g. offline first launch) doesn't count, so nothing gets wrongly removed.
    @Published private(set) var hasLoaded = false

    private let collection: CollectionReference
    private let listener = GroupsListenerBox()

    init(userId: String) {
        collection = FirestoreTransactionManager.profileDocument(for: userId).collection("groups")
        listener.registration = collection.addSnapshotListener { [weak self] snapshot, error in
            guard let snapshot else {
                print("☁️ Groups listen error: \(error?.localizedDescription ?? "unknown")")
                return
            }
            let isTrustworthy = !(snapshot.metadata.isFromCache && snapshot.documents.isEmpty)
            let groups: [ExpenseGroup] = snapshot.documents.compactMap { document in
                guard var group = try? document.data(as: ExpenseGroup.self) else { return nil }
                group.id = document.documentID
                return group
            }
            Task { @MainActor in
                guard let self else { return }
                if !isTrustworthy && !self.hasLoaded { return }
                self.groups = groups.sorted { $0.createdAt > $1.createdAt }
                self.hasLoaded = true
            }
        }
    }

    func group(withID id: String) -> ExpenseGroup? {
        groups.first { $0.id == id }
    }

    // MARK: - Groups

    func save(_ group: ExpenseGroup) {
        if let index = groups.firstIndex(where: { $0.id == group.id }) {
            groups[index] = group
        } else {
            groups.insert(group, at: 0)
        }
        do {
            try collection.document(group.id).setData(from: group)
        } catch {
            print("☁️ Group save failed: \(error)")
        }
    }

    func delete(_ group: ExpenseGroup) {
        groups.removeAll { $0.id == group.id }
        collection.document(group.id).delete()
    }

    // MARK: - Expenses

    func upsert(_ expense: GroupExpense, in groupID: String) {
        guard var group = group(withID: groupID) else { return }
        if let index = group.expenses.firstIndex(where: { $0.id == expense.id }) {
            group.expenses[index] = expense
        } else {
            group.expenses.append(expense)
        }
        save(group)
    }

    func deleteExpense(_ expense: GroupExpense, in groupID: String) {
        guard var group = group(withID: groupID) else { return }
        group.expenses.removeAll { $0.id == expense.id }
        save(group)
    }

    // MARK: - Settling up

    func recordPayment(_ payment: GroupPayment, in groupID: String) {
        guard var group = group(withID: groupID) else { return }
        group.payments.append(payment)
        save(group)
    }

    func deletePayment(_ payment: GroupPayment, in groupID: String) {
        guard var group = group(withID: groupID) else { return }
        group.payments.removeAll { $0.id == payment.id }
        save(group)
    }
}

private final class GroupsListenerBox {
    var registration: ListenerRegistration?
    deinit { registration?.remove() }
}

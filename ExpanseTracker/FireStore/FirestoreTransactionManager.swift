//
//  FirestoreTransactionManager.swift
//  ExpanseTracker
//
//  Created by KPIT on 02/08/25.
//


import Foundation
import FirebaseFirestore
import CoreData

final class FirestoreTransactionManager: ObservableObject {
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let userId: String
    private let context: NSManagedObjectContext
    var onTransactionSynced: (([Transaction]) -> Void)?

    init(userId: String, context: NSManagedObjectContext) {
        self.userId = userId
        self.context = context
        listenToTransactions()
    }

    deinit {
        listener?.remove()
    }

    private func listenToTransactions() {
        listener = db.collection("users")
            .document(userId)
            .collection("transactions")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let documents = snapshot?.documents {
                    let remoteTransactions: [Transaction] = documents.compactMap {
                        try? $0.data(as: Transaction.self)
                    }

                    // Sync with Core Data (overwrite local data with Firestore data)
                    self.syncLocalWithRemote(remoteTransactions)
                    self.onTransactionSynced?(remoteTransactions)
                } else if let error = error {
                    print("Firestore fetch error: \(error.localizedDescription)")
                }
            }
    }

    func addTransaction(_ txn: Transaction) async throws {
        let id = txn.id ?? UUID().uuidString
        try db.collection("users")
            .document(userId)
            .collection("transactions")
            .document(id)
            .setData(from: txn)
    }

    func updateTransaction(_ txn: Transaction) async throws {
        guard let id = txn.id else { return }
        try db.collection("users")
            .document(userId)
            .collection("transactions")
            .document(id)
            .setData(from: txn)
    }

    func deleteTransaction(_ txn: Transaction) async throws {
        guard let id = txn.id else { return }
        try await db.collection("users")
            .document(userId)
            .collection("transactions")
            .document(id)
            .delete()
    }

    private func syncLocalWithRemote(_ remoteTransactions: [Transaction]) {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()

        do {
            let localEntities = try context.fetch(fetchRequest)

            // Delete local entries not in remote
            for local in localEntities {
                if !remoteTransactions.contains(where: { $0.id == local.id }) {
                    context.delete(local)
                }
            }

            // Add or update local entries
            for remote in remoteTransactions {
                if let existing = localEntities.first(where: { $0.id == remote.id }) {
                    existing.title = remote.title
                    existing.amount = remote.amount
                    existing.date = remote.date
                    existing.type = remote.type.rawValue
                } else {
                    let newEntity = TransactionEntity(context: context)
                    newEntity.id = remote.id
                    newEntity.title = remote.title
                    newEntity.amount = remote.amount
                    newEntity.date = remote.date
                    newEntity.type = remote.type.rawValue
                }
            }

            try context.save()

        } catch {
            print("Failed syncing Firestore to CoreData: \(error)")
        }
    }
}

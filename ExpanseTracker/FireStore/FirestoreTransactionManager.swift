//
//  FirestoreTransactionManager.swift
//  ExpanseTracker
//
//  Created by KPIT on 02/08/25.
//

import Foundation
import FirebaseFirestore

/// Thin remote layer over `users/{uid}/transactions`.
/// It never touches Core Data; `TransactionManager` owns local state.
final class FirestoreTransactionManager {

    private let collection: CollectionReference
    private var listener: ListenerRegistration?

    init(userId: String) {
        collection = Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("transactions")
    }

    deinit {
        listener?.remove()
    }

    /// Delivers the full remote list on the main queue whenever it changes.
    func startListening(onChange: @escaping ([Transaction]) -> Void) {
        listener?.remove()
        listener = collection.addSnapshotListener { snapshot, error in
            guard let snapshot else {
                print("☁️ Firestore listen error: \(error?.localizedDescription ?? "unknown")")
                return
            }

            // An empty *cached* snapshot (e.g. first launch while offline) means
            // "don't know yet", not "user has no transactions". Don't wipe local data.
            if snapshot.metadata.isFromCache && snapshot.documents.isEmpty { return }

            let transactions: [Transaction] = snapshot.documents.compactMap { document in
                guard var txn = try? document.data(as: Transaction.self) else {
                    print("☁️ Skipping undecodable transaction \(document.documentID)")
                    return nil
                }
                txn.id = document.documentID
                return txn
            }
            onChange(transactions)
        }
    }

    func save(_ txn: Transaction) throws {
        guard let id = txn.id else { return }
        try collection.document(id).setData(from: txn)
    }

    func delete(_ txn: Transaction) async throws {
        guard let id = txn.id else { return }
        try await collection.document(id).delete()
    }
}

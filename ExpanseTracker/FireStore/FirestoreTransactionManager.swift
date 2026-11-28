//
//  FirestoreTransactionManager.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 02/08/25.
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

    // MARK: - Profile

    static func profileDocument(for userId: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(userId)
    }

    /// Permanently removes every transaction and the profile document for this user.
    static func deleteAllData(for userId: String) async throws {
        let db = Firestore.firestore()
        let profile = profileDocument(for: userId)
        let documents = try await profile.collection("transactions").getDocuments().documents

        // Firestore batches are capped at 500 writes.
        for start in stride(from: 0, to: documents.count, by: 400) {
            let batch = db.batch()
            documents[start..<min(start + 400, documents.count)].forEach { batch.deleteDocument($0.reference) }
            try await batch.commit()
        }
        try await profile.delete()
    }

    // MARK: - Transactions

    func save(_ txn: Transaction) throws {
        guard let id = txn.id else { return }
        try collection.document(id).setData(from: txn)
    }

    func delete(_ txn: Transaction) async throws {
        guard let id = txn.id else { return }
        try await collection.document(id).delete()
    }
}

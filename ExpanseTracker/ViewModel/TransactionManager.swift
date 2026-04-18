import Foundation
import CoreData
import SwiftUI

class TransactionManager: ObservableObject {
    private let context: NSManagedObjectContext
    private weak var firestoreManager: FirestoreTransactionManager?

    @Published var transactions: [Transaction] = []

    init(context: NSManagedObjectContext, firestoreManager: FirestoreTransactionManager? = nil) {
        self.context = context
        self.firestoreManager = firestoreManager
        fetchTransactions()
        firestoreManager?.onTransactionSynced = { [weak self]  transactions in
            self?.syncFromFirestore(transactions)
        }
    }
    
    private func syncFromFirestore(_ remoteTransactions: [Transaction]) {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()

        do {
            let existingEntities = try context.fetch(fetchRequest)

            // Map existing by ID for quick lookup
            var existingMap: [String: TransactionEntity] = Dictionary(uniqueKeysWithValues: existingEntities.compactMap {
                guard let id = $0.id else { return nil }
                return (id, $0)
            })


            for txn in remoteTransactions {
                guard let id = txn.id else { continue }

                if let entity = existingMap[id] {
                    // Update existing
                    entity.title = txn.title
                    entity.amount = txn.amount
                    entity.date = txn.date
                    entity.type = txn.type.rawValue
                    existingMap.removeValue(forKey: id)
                } else {
                    // New transaction from Firestore
                    let newEntity = TransactionEntity(context: context)
                    newEntity.id = id
                    newEntity.title = txn.title
                    newEntity.amount = txn.amount
                    newEntity.date = txn.date
                    newEntity.type = txn.type.rawValue
                }
            }

            // Optional: delete leftover entities not in Firestore (if desired)
            // for entity in existingMap.values {
            //     context.delete(entity)
            // }

            try context.save()
            fetchTransactions()
        } catch {
            print("Failed to sync from Firestore: \(error)")
        }
    }

    func fetchTransactions() {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let entities = try context.fetch(request)
            self.transactions = entities.map { entity in
                Transaction(
                    id: entity.id ?? UUID().uuidString,
                    titile: entity.title ?? "",
                    amount: entity.amount,
                    date: entity.date ?? Date(),
                    type: TransactionType(rawValue: entity.type ?? "expense") ?? .expanse
                )
            }
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
    }

    func addTransaction(title: String, amount: Double, date: Date, type: TransactionType, category: TransactionCategory) {
        let newEntity = TransactionEntity(context: context)
        newEntity.id = UUID().uuidString
        newEntity.title = title
        newEntity.amount = amount
        newEntity.date = date
        newEntity.type = type.rawValue
        newEntity.category = category.rawValue   // ✅ ADD THIS

        saveContext()
        let txn = Transaction(
            id: newEntity.id ?? UUID().uuidString,
            titile: title,
            amount: amount,
            date: date,
            type: type,
            category: category   // ✅ ADD THIS
        )
        Task {
            try? await firestoreManager?.addTransaction(txn)
        }
//        fetchTransactions()
    }

    func updateTransaction(_ transaction: Transaction) {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", transaction.id ?? "")

        do {
            if let entity = try context.fetch(request).first {
                entity.title = transaction.title
                entity.amount = transaction.amount
                entity.date = transaction.date
                entity.type = transaction.type.rawValue

                saveContext()
                fetchTransactions()
            }
        } catch {
            print("Update failed: \(error)")
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", transaction.id ?? "")

        do {
            if let entity = try context.fetch(request).first {
                context.delete(entity)
                saveContext()
                fetchTransactions()
            }
        } catch {
            print("Delete failed: \(error)")
        }
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Save failed: \(error)")
        }
    }
}

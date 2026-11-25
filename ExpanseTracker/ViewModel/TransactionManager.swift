//
//  TransactionManager.swift
//  ExpanseTracker
//

import Foundation
import CoreData

/// Single source of truth for transactions.
/// Core Data gives instant, offline-capable UI; Firestore is the cloud copy.
/// Every add / update / delete goes through here so both stay in step.
@MainActor
final class TransactionManager: ObservableObject {

    @Published private(set) var transactions: [Transaction] = []

    private let context: NSManagedObjectContext
    private let remote: FirestoreTransactionManager?

    init(context: NSManagedObjectContext, remote: FirestoreTransactionManager? = nil) {
        self.context = context
        self.remote = remote
        fetchTransactions()

        remote?.startListening { [weak self] remoteTransactions in
            Task { @MainActor in
                self?.syncFromRemote(remoteTransactions)
            }
        }
    }

    // MARK: - CRUD

    func add(_ txn: Transaction) {
        upsertLocal(txn)
        saveAndReload()
        pushToRemote { try $0.save(txn) }
    }

    func update(_ txn: Transaction) {
        upsertLocal(txn)
        saveAndReload()
        pushToRemote { try $0.save(txn) }
    }

    func delete(_ txn: Transaction) {
        if let id = txn.id, let entity = entity(withID: id) {
            context.delete(entity)
            saveAndReload()
        }
        pushToRemote { try await $0.delete(txn) }
    }

    // MARK: - Remote → Local

    /// Makes Core Data mirror the remote list exactly (adds, updates and deletes).
    private func syncFromRemote(_ remoteTransactions: [Transaction]) {
        let entities = (try? context.fetch(TransactionEntity.fetchRequest())) ?? []

        var localByID: [String: TransactionEntity] = [:]
        for entity in entities {
            guard let id = entity.id else { continue }
            if localByID[id] != nil {
                context.delete(entity) // duplicate row
            } else {
                localByID[id] = entity
            }
        }

        var remoteIDs = Set<String>()
        for txn in remoteTransactions {
            guard let id = txn.id else { continue }
            remoteIDs.insert(id)
            let entity = localByID[id] ?? TransactionEntity(context: context)
            apply(txn, to: entity)
        }

        for (id, entity) in localByID where !remoteIDs.contains(id) {
            context.delete(entity)
        }

        saveAndReload()
    }

    // MARK: - Core Data helpers

    func fetchTransactions() {
        let request = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            transactions = try context.fetch(request).map { entity in
                Transaction(
                    id: entity.id ?? UUID().uuidString,
                    title: entity.title ?? "",
                    amount: entity.amount,
                    date: entity.date ?? Date(),
                    type: TransactionType(rawValue: entity.type ?? "") ?? .expense,
                    category: TransactionCategory(rawValue: entity.category ?? "") ?? .other
                )
            }
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
    }

    private func upsertLocal(_ txn: Transaction) {
        let id = txn.id ?? UUID().uuidString
        let entity = entity(withID: id) ?? TransactionEntity(context: context)
        var txn = txn
        txn.id = id
        apply(txn, to: entity)
    }

    private func apply(_ txn: Transaction, to entity: TransactionEntity) {
        entity.id = txn.id
        entity.title = txn.title
        entity.amount = txn.amount
        entity.date = txn.date
        entity.type = txn.type.rawValue
        entity.category = txn.category.rawValue
    }

    private func entity(withID id: String) -> TransactionEntity? {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func saveAndReload() {
        do {
            if context.hasChanges { try context.save() }
        } catch {
            print("Save failed: \(error)")
        }
        fetchTransactions()
    }

    private func pushToRemote(_ operation: @escaping (FirestoreTransactionManager) async throws -> Void) {
        guard let remote else { return }
        Task {
            do {
                try await operation(remote)
            } catch {
                print("☁️ Remote sync failed: \(error)")
            }
        }
    }
}

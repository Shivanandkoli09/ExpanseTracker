import Foundation
import CoreData
import SwiftUI

class TransactionManager: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var transactions: [Transaction] = []

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchTransactions()
    }

    func fetchTransactions() {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let entities = try context.fetch(request)
            self.transactions = entities.map { entity in
                Transaction(
                    id: entity.id ?? UUID(),
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

    func addTransaction(title: String, amount: Double, date: Date, type: TransactionType) {
        let newEntity = TransactionEntity(context: context)
        newEntity.id = UUID()
        newEntity.title = title
        newEntity.amount = amount
        newEntity.date = date
        newEntity.type = type.rawValue

        saveContext()
        fetchTransactions()
    }

    func updateTransaction(_ transaction: Transaction) {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)

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
        request.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)

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

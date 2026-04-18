//
//  AITransactionClassifier.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 18/04/26.
//

final class AITransactionClassifier {

    static let shared = AITransactionClassifier()

    private init() {}

    func predict(title: String) -> (type: TransactionType, category: TransactionCategory) {
        let text = title.lowercased()

        // MARK: - Income detection
        if text.contains("salary") || text.contains("bonus") || text.contains("freelance") {
            return (.income, .salary)
        }

        // MARK: - Transport
        if text.contains("uber") || text.contains("ola") || text.contains("taxi") || text.contains("petrol") {
            return (.expanse, .transport)
        }

        // MARK: - Food
        if text.contains("zomato") || text.contains("swiggy") || text.contains("restaurant") || text.contains("food") {
            return (.expanse, .food)
        }

        // MARK: - Shopping
        if text.contains("amazon") || text.contains("flipkart") || text.contains("shopping") {
            return (.expanse, .shopping)
        }

        // MARK: - Entertainment
        if text.contains("netflix") || text.contains("movie") || text.contains("spotify") {
            return (.expanse, .entertainment)
        }

        // MARK: - Bills
        if text.contains("electricity") || text.contains("bill") || text.contains("rent") {
            return (.expanse, .bills)
        }

        // Default
        return (.expanse, .other)
    }
}

//
//  AITransactionClassifier.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 18/04/26.
//

import NaturalLanguage

final class AITransactionClassifier {

    static let shared = AITransactionClassifier()

    private init() {}

    func predict(title: String) -> (type: TransactionType, category: TransactionCategory) {
        
        let lowercased = title.lowercased()
        
        // ✅ Step 1: Tokenize words using Apple NLP
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = lowercased
        
        var tokens: [String] = []
        
        tokenizer.enumerateTokens(in: lowercased.startIndex..<lowercased.endIndex) { range, _ in
            let word = String(lowercased[range])
            tokens.append(word)
            return true
        }

        // ✅ Step 2: Smarter matching using tokens
        let tokenSet = Set(tokens)

        // MARK: - Income
        if tokenSet.contains("salary") || tokenSet.contains("bonus") || tokenSet.contains("freelance") {
            return (.income, .salary)
        }

        // MARK: - Transport
        if tokenSet.contains("uber") || tokenSet.contains("ola") || tokenSet.contains("taxi") || tokenSet.contains("petrol") {
            return (.expanse, .transport)
        }

        // MARK: - Food
        if tokenSet.contains("zomato") || tokenSet.contains("swiggy") || tokenSet.contains("restaurant") || tokenSet.contains("food") {
            return (.expanse, .food)
        }

        // MARK: - Shopping
        if tokenSet.contains("amazon") || tokenSet.contains("flipkart") || tokenSet.contains("shopping") {
            return (.expanse, .shopping)
        }

        // MARK: - Entertainment
        if tokenSet.contains("netflix") || tokenSet.contains("movie") || tokenSet.contains("spotify") {
            return (.expanse, .entertainment)
        }

        // MARK: - Bills
        if tokenSet.contains("electricity") || tokenSet.contains("bill") || tokenSet.contains("rent") {
            return (.expanse, .bills)
        }

        return (.expanse, .other)
    }
}

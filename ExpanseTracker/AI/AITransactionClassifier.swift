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

    private static let stopWords: Set<String> = [
        "the", "and", "for", "from", "with", "paid", "pay", "payment", "via", "my", "to", "at", "on", "of", "in",
        "today", "yesterday", "monthly", "weekly",
        "jan", "january", "feb", "february", "mar", "march", "apr", "april", "may", "june", "july",
        "aug", "august", "sep", "sept", "september", "oct", "october", "nov", "november", "dec", "december"
    ]

    /// Checked in order; the first category with a matching word wins.
    private let rules: [(category: TransactionCategory, keywords: Set<String>)] = [
        (.salary, ["salary", "bonus", "freelance", "payroll", "stipend", "income"]),
        (.transport, ["uber", "ola", "rapido", "taxi", "cab", "petrol", "diesel", "fuel", "metro", "bus", "train", "parking", "toll"]),
        (.food, ["zomato", "swiggy", "restaurant", "food", "lunch", "dinner", "breakfast", "cafe", "coffee", "pizza", "groceries", "grocery"]),
        (.shopping, ["amazon", "flipkart", "myntra", "meesho", "ajio", "shopping", "clothes", "shoes"]),
        (.entertainment, ["netflix", "movie", "movies", "spotify", "hotstar", "prime", "concert", "bookmyshow"]),
        (.bills, ["electricity", "bill", "rent", "recharge", "wifi", "internet", "broadband", "water", "gas", "emi", "insurance"])
    ]

    // MARK: - Prediction

    func predict(title: String) -> (type: TransactionType, category: TransactionCategory) {
        let tokens = Self.tokens(in: title)

        // 1. What this user taught us wins over built-in rules.
        for token in tokens {
            if let learned = UserPreferenceStore.shared.getPreference(for: token) {
                return (learned.defaultType, learned)
            }
        }

        // 2. Built-in keyword rules.
        let tokenSet = Set(tokens)
        for rule in rules where !tokenSet.isDisjoint(with: rule.keywords) {
            return (rule.category.defaultType, rule.category)
        }

        return (.expense, .other)
    }

    // MARK: - Tokens

    /// Lower-cased words, using Apple's NLP tokenizer.
    static func tokens(in title: String) -> [String] {
        let text = title.lowercased()
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        var tokens: [String] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            tokens.append(String(text[range]))
            return true
        }
        return tokens
    }

    /// The word worth remembering when the user corrects a category,
    /// e.g. "Paid 250 to Chaayos" → "chaayos".
    static func keyword(in title: String) -> String? {
        tokens(in: title).first { token in
            token.count >= 3 && !stopWords.contains(token) && Double(token) == nil
        }
    }
}

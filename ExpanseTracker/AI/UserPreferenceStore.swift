//
//  UserPreferenceStore.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 18/04/26.
//

import Foundation

final class UserPreferenceStore {

    static let shared = UserPreferenceStore()

    private let key = "user_category_preferences"

    private init() {}

    // Save user preference
    func savePreference(keyword: String, category: TransactionCategory) {
        var preferences = getPreferences()
        preferences[keyword.lowercased()] = category.rawValue
        UserDefaults.standard.set(preferences, forKey: key)
    }

    // Fetch preference
    func getPreference(for keyword: String) -> TransactionCategory? {
        let preferences = getPreferences()
        if let raw = preferences[keyword.lowercased()] {
            return TransactionCategory(rawValue: raw)
        }
        return nil
    }

    private func getPreferences() -> [String: String] {
        return UserDefaults.standard.dictionary(forKey: key) as? [String: String] ?? [:]
    }
}

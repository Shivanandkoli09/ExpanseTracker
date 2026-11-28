//
//  CategoryStyle.swift
//  ExpanseTracker
//

import SwiftUI

extension TransactionCategory {
    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .shopping:      return "bag.fill"
        case .bills:         return "bolt.fill"
        case .entertainment: return "film.fill"
        case .salary:        return "briefcase.fill"
        case .other:         return "square.grid.2x2.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:          return .orange
        case .transport:     return .blue
        case .shopping:      return .purple
        case .bills:         return .red
        case .entertainment: return .pink
        case .salary:        return .green
        case .other:         return .gray
        }
    }
}

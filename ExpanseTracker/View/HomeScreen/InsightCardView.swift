//
//  InsightCardView.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 19/04/26.
//

import SwiftUI

struct InsightCardView: View {

    let insight: Insight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(insight.message)
                .font(.caption)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }

    private var iconName: String {
        switch insight.type {
        case .info: return "lightbulb"
        case .warning: return "exclamationmark.triangle"
        case .positive: return "checkmark.circle"
        }
    }

    private var iconColor: Color {
        switch insight.type {
        case .info: return .blue
        case .warning: return .orange
        case .positive: return .green
        }
    }

    private var backgroundColor: Color {
        switch insight.type {
        case .info: return Color.blue.opacity(0.1)
        case .warning: return Color.orange.opacity(0.15)
        case .positive: return Color.green.opacity(0.15)
        }
    }
}

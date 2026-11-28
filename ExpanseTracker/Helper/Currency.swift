//
//  Currency.swift
//  ExpanseTracker
//

import Foundation

/// Indian-style rupee formatting: ₹12,40,000 and ₹250.50
enum Currency {
    private static let whole = makeFormatter(fractionDigits: 0)
    private static let decimal = makeFormatter(fractionDigits: 2)

    private static func makeFormatter(fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter
    }

    static func string(_ value: Double) -> String {
        let formatter = value.rounded() == value ? whole : decimal
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(value)"
    }

    /// Short form for chart axes: ₹950, ₹12k, ₹1.2L
    static func compact(_ value: Double) -> String {
        let absValue = abs(value)
        switch absValue {
        case 1_00_000...:
            return "₹" + trimmed(value / 1_00_000) + "L"
        case 1_000...:
            return "₹" + trimmed(value / 1_000) + "k"
        default:
            return "₹" + String(Int(value))
        }
    }

    private static func trimmed(_ value: Double) -> String {
        let text = String(format: "%.1f", value)
        return text.hasSuffix(".0") ? String(text.dropLast(2)) : text
    }
}

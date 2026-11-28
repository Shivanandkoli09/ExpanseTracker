//
//  TransactionsCSV.swift
//  ExpanseTracker
//
//  Exports transactions as a CSV file for the share sheet.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct TransactionsCSV: Transferable {
    let transactions: [Transaction]

    var fileName: String {
        let stamp = Date().formatted(.iso8601.year().month().day())
        return "MyMoney-Transactions-\(stamp).csv"
    }

    var text: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var lines = ["Date,Title,Type,Category,Amount (INR)"]
        for txn in transactions.sorted(by: { $0.date > $1.date }) {
            let amount = (txn.type == .expense ? -txn.amount : txn.amount)
            lines.append([
                dateFormatter.string(from: txn.date),
                Self.escape(txn.title),
                txn.type.rawValue,
                txn.category.displayName,
                String(format: "%.2f", amount)
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Quotes fields containing commas, quotes or new lines (RFC 4180).
    /// Also neutralises leading = + - @ so spreadsheets don't run them as formulas.
    private static func escape(_ field: String) -> String {
        var value = field
        if let first = value.first, "=+-@".contains(first) {
            value = "'" + value
        }
        if value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(csv.fileName)
            try csv.text.write(to: url, atomically: true, encoding: .utf8)
            return SentTransferredFile(url)
        }
    }
}

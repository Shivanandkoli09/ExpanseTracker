//
//  UPIPayment.swift
//  ExpanseTracker
//
//  UPI payment links and QR codes. Any UPI app (GPay, PhonePe, Paytm, BHIM…)
//  can scan these and open a payment with the amount already filled in.
//

import UIKit
import CoreImage.CIFilterBuiltins

enum UPIPayment {

    /// e.g. name@okhdfcbank, 98xxxxxx10@ybl
    static func isValidID(_ id: String) -> Bool {
        id.trimmingCharacters(in: .whitespaces)
            .range(of: #"^[A-Za-z0-9.\-_]{2,256}@[A-Za-z][A-Za-z0-9]{1,64}$"#, options: .regularExpression) != nil
    }

    /// Standard UPI deep link: upi://pay?pa=…&pn=…&am=…&cu=INR&tn=…
    static func link(payeeID: String, payeeName: String, amount: Double, note: String) -> URL? {
        var components = URLComponents()
        components.scheme = "upi"
        components.host = "pay"
        components.queryItems = [
            URLQueryItem(name: "pa", value: payeeID),
            URLQueryItem(name: "pn", value: payeeName),
            URLQueryItem(name: "am", value: String(format: "%.2f", amount)),
            URLQueryItem(name: "cu", value: "INR"),
            URLQueryItem(name: "tn", value: plainNote(note))
        ]
        return components.url
    }

    /// Some UPI apps reject notes with emoji or symbols: keep letters, digits and spaces.
    static func plainNote(_ note: String) -> String {
        let allowed = note.unicodeScalars.filter { $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == " ") }
        let cleaned = String(String.UnicodeScalarView(allowed))
            .split(separator: " ").joined(separator: " ")
        return String((cleaned.isEmpty ? "MyMoney split" : cleaned).prefix(50))
    }

    static func qrImage(for string: String, scale: CGFloat = 12) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: scale, y: scale)),
              let cgImage = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

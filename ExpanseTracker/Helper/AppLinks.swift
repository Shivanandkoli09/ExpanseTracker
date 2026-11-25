//
//  AppLinks.swift
//  ExpanseTracker
//

import Foundation

/// External links shown in Profile. Rows are hidden while a value is `nil`.
enum AppLinks {
    /// Required by App Store review for apps with accounts. Set before submitting.
    static let privacyPolicy: URL? = nil
    static let termsOfUse: URL? = nil
    static let supportEmail: String? = nil
}

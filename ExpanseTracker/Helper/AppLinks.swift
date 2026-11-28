//
//  AppLinks.swift
//  ExpanseTracker
//

import Foundation

/// External links shown in Profile. Rows are hidden while a value is `nil`.
/// Pages live in `/docs` and are served by GitHub Pages.
enum AppLinks {
    private static let site = "https://shivanandkoli09.github.io/ExpanseTracker"

    static let privacyPolicy = URL(string: "\(site)/privacy.html")
    static let helpAndSupport = URL(string: "\(site)/support.html")
    static let termsOfUse: URL? = nil

    /// Set to the support address once it exists, e.g. "mymoney.support@gmail.com".
    /// Must match the address in docs/privacy.html and docs/support.html.
    static let supportEmail: String? = nil
}

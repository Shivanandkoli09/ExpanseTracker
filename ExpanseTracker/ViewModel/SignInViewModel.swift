//
//  SignInViewModel.swift
//  ExpanseTracker
//
//  Created by KPIT on 29/07/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Auth Mode

enum AuthMode: String, CaseIterable, Identifiable {
    case signIn = "Sign In"
    case signUp = "Create Account"

    var id: String { rawValue }
}

// MARK: - Saving Goal
/// Asked once during sign-up. Stored on the user profile so the app can later
/// frame insights around *why* the user is saving, not just *what* they spent.
enum SavingGoal: String, CaseIterable, Identifiable, Codable {
    case emergency, travel, gadget, home, education, freedom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emergency: return "Emergency Fund"
        case .travel:    return "Dream Trip"
        case .gadget:    return "New Gadget"
        case .home:      return "Own a Home"
        case .education: return "Education"
        case .freedom:   return "Debt Free"
        }
    }

    var emoji: String {
        switch self {
        case .emergency: return "🛟"
        case .travel:    return "✈️"
        case .gadget:    return "📱"
        case .home:      return "🏡"
        case .education: return "🎓"
        case .freedom:   return "🕊️"
        }
    }
}

// MARK: - Password Strength

enum PasswordStrength: Int, Comparable {
    case empty, weak, fair, good, strong

    init(_ password: String) {
        guard !password.isEmpty else { self = .empty; return }
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil,
           password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil { score += 1 }

        switch score {
        case 0...1: self = .weak
        case 2:     self = .fair
        case 3:     self = .good
        default:    self = .strong
        }
    }

    var label: String {
        switch self {
        case .empty:  return ""
        case .weak:   return "Weak"
        case .fair:   return "Fair"
        case .good:   return "Good"
        case .strong: return "Strong"
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

// MARK: - ViewModel

@MainActor
final class SignInViewModel: ObservableObject {

    // Form
    @Published var mode: AuthMode = .signIn
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var savingGoal: SavingGoal?

    // State
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Session
    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var userID: String?
    @Published private(set) var displayName: String?

    /// Kept for the lifetime of the app (this view model is owned by the App).
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        Self.clearStaleSessionAfterReinstall()
        let user = Auth.auth().currentUser
        isLoggedIn = user != nil
        userID = user?.uid
        displayName = user?.displayName

        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.apply(user: user)
            }
        }

        // If the account was deleted/disabled on the server, the cached session is stale.
        if let user {
            Task {
                do {
                    try await user.reload()
                } catch {
                    try? Auth.auth().signOut()
                }
            }
        }
    }

    // MARK: - Validation

    var trimmedEmail: String { email.trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var isEmailValid: Bool {
        trimmedEmail.range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#,
                           options: .regularExpression) != nil
    }

    var passwordStrength: PasswordStrength { PasswordStrength(password) }

    var isPasswordValidForSignUp: Bool { password.count >= 8 && passwordStrength >= .fair }

    var canSubmit: Bool {
        guard !isLoading else { return false }
        switch mode {
        case .signIn: return isEmailValid && !password.isEmpty
        case .signUp: return !trimmedName.isEmpty && isEmailValid && isPasswordValidForSignUp
        }
    }

    // MARK: - Actions

    func switchMode(to newMode: AuthMode) {
        guard newMode != mode else { return }
        mode = newMode
        errorMessage = nil
        password = ""
    }

    func submit() async {
        guard canSubmit else { return }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            switch mode {
            case .signIn:
                try await FirebaseAuthManager.shared.signIn(email: trimmedEmail, password: password)
            case .signUp:
                let result = try await FirebaseAuthManager.shared.createUser(email: trimmedEmail, password: password)
                await saveProfile(uid: result.uid)
            }
            password = ""
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    /// Returns `nil` on success, or a user-facing error message.
    func sendPasswordReset(to address: String) async -> String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await FirebaseAuthManager.shared.resetPasword(email: trimmed)
            return nil
        } catch {
            return Self.friendlyMessage(for: error)
        }
    }

    func logout() {
        do {
            try FirebaseAuthManager.shared.signOut()
            name = ""
            email = ""
            password = ""
            savingGoal = nil
            mode = .signIn
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Re-reads the signed-in user, e.g. after the display name changes.
    func refreshUser() {
        apply(user: Auth.auth().currentUser)
    }

    // MARK: - Private

    /// Firebase keeps the session in the Keychain, which survives app deletion,
    /// while UserDefaults does not. On the first launch after a (re)install,
    /// start signed out instead of flashing into a stale session.
    private static func clearStaleSessionAfterReinstall() {
        let key = "hasLaunchedBefore"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        try? Auth.auth().signOut()
        UserDefaults.standard.set(true, forKey: key)
    }

    private func apply(user: User?) {
        isLoggedIn = user != nil
        userID = user?.uid
        displayName = user?.displayName
    }

    /// Best-effort: a failure here should never block the user from entering the app.
    private func saveProfile(uid: String) async {
        if let user = Auth.auth().currentUser {
            let change = user.createProfileChangeRequest()
            change.displayName = trimmedName
            try? await change.commitChanges()
            displayName = trimmedName
        }

        var data: [String: Any] = [
            "name": trimmedName,
            "email": trimmedEmail,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let savingGoal { data["savingGoal"] = savingGoal.rawValue }

        try? await Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData(data, merge: true)
    }

    static func friendlyMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return "Something went wrong. Please try again."
        }

        switch code {
        case .invalidEmail:
            return "That email address doesn't look right."
        case .wrongPassword, .invalidCredential, .userNotFound:
            return "Email or password is incorrect."
        case .emailAlreadyInUse:
            return "An account with this email already exists. Try signing in."
        case .weakPassword:
            return "Please choose a stronger password."
        case .networkError:
            return "You're offline. Check your connection and try again."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .requiresRecentLogin:
            return "For your security, please enter your password again."
        case .userDisabled:
            return "This account has been disabled. Contact support for help."
        default:
            return "Something went wrong. Please try again."
        }
    }
}

//
//  ProfileViewModel.swift
//  ExpanseTracker
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ProfileViewModel: ObservableObject {

    struct Message: Identifiable {
        let id = UUID()
        let title: String
        let body: String
    }

    @Published private(set) var name: String = ""
    @Published private(set) var email: String = ""
    @Published private(set) var memberSince: Date?
    @Published private(set) var savingGoal: SavingGoal?
    @Published private(set) var isDeleting = false
    @Published var message: Message?

    private let uid: String?

    init() {
        let user = Auth.auth().currentUser
        uid = user?.uid
        name = user?.displayName ?? ""
        email = user?.email ?? ""
        memberSince = user?.metadata.creationDate
    }

    var displayName: String {
        name.isEmpty ? "MyMoney User" : name
    }

    var initials: String {
        let source = name.isEmpty ? email : name
        let letters = source
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
        return letters.isEmpty ? "?" : letters.uppercased()
    }

    // MARK: - Profile

    func loadProfile() async {
        guard let uid else { return }
        let snapshot = try? await FirestoreTransactionManager.profileDocument(for: uid).getDocument()
        savingGoal = (snapshot?.data()?["savingGoal"] as? String).flatMap(SavingGoal.init(rawValue:))
    }

    func setSavingGoal(_ goal: SavingGoal?) async {
        guard let uid else { return }
        let previous = savingGoal
        savingGoal = goal
        do {
            try await FirestoreTransactionManager.profileDocument(for: uid)
                .setData(["savingGoal": goal?.rawValue ?? FieldValue.delete()], merge: true)
        } catch {
            savingGoal = previous
            message = Message(title: "Couldn't update goal", body: SignInViewModel.friendlyMessage(for: error))
        }
    }

    /// Returns `true` when the name was saved.
    func updateName(_ newName: String) async -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != name, let uid else { return false }
        do {
            try await FirebaseAuthManager.shared.updateDisplayName(trimmed)
            try? await FirestoreTransactionManager.profileDocument(for: uid)
                .setData(["name": trimmed], merge: true)
            name = trimmed
            return true
        } catch {
            message = Message(title: "Couldn't update name", body: SignInViewModel.friendlyMessage(for: error))
            return false
        }
    }

    func sendPasswordReset() async {
        do {
            try await FirebaseAuthManager.shared.resetPasword(email: email)
            message = Message(title: "Check your inbox",
                              body: "We sent a link to \(email) to set a new password.")
        } catch {
            message = Message(title: "Couldn't send email", body: SignInViewModel.friendlyMessage(for: error))
        }
    }

    // MARK: - Delete Account

    /// Returns `nil` on success, otherwise a user-facing error.
    /// On success the auth listener signs the app out and local data is cleared.
    func deleteAccount(password: String) async -> String? {
        guard let uid else { return "You're not signed in." }
        isDeleting = true
        defer { isDeleting = false }

        do {
            // Order matters: re-auth first (Firebase requires a recent login),
            // then cloud data while we still have permission, then the account itself.
            try await FirebaseAuthManager.shared.reauthenticate(email: email, password: password)
            try await FirestoreTransactionManager.deleteAllData(for: uid)
            try await FirebaseAuthManager.shared.deleteCurrentUser()

            UserPreferenceStore.shared.clearAll()
            NotificationManager.shared.cancelDailyReminder()
            return nil
        } catch {
            return SignInViewModel.friendlyMessage(for: error)
        }
    }
}

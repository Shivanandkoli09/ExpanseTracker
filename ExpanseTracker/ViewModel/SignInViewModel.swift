//
//  SignInViewModel.swift
//  ExpanseTracker
//
//  Created by KPIT on 29/07/25.
//

import Foundation
import FirebaseAuth

@MainActor
final class SignInViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = (Auth.auth().currentUser != nil)
    @Published var errorMessage: String?
    
    init() {
        self.isLoggedIn = (try? FirebaseAuthManager.shared.getAuthenticatedUser()) != nil
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        do {
            try await FirebaseAuthManager.shared.createUser(email: email, password: password)
            self.isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        do {
            try await FirebaseAuthManager.shared.signIn(email: email, password: password)
            self.isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        do {
            try FirebaseAuthManager.shared.signOut()
            self.isLoggedIn = false
            email = ""
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

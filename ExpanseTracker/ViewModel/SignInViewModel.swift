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
    @Published var userID: String? = nil
    
//    init() {
//        if let user = try? FirebaseAuthManager.shared.getAuthenticatedUser() {
//            self.isLoggedIn = true
//            self.userID = user.uid
//        } else {
//            self.userID = nil
//            self.isLoggedIn = false
//        }
//    }
    
    init () {
        Task {
            if let user = Auth.auth().currentUser {
                do {
                    _ = try await user.getIDTokenResult(forcingRefresh: true)
                    await MainActor.run {
                        self.isLoggedIn = true
                        self.userID = user.uid
                    }
                } catch {
                    await MainActor.run {
                        self.isLoggedIn = false
                        self.userID = nil
                    }
                }
            } else {
                self.isLoggedIn = false
            }
        }
    }

    func signUp() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password"
            return
        }
        do {
            try await FirebaseAuthManager.shared.createUser(email: email, password: password)
            self.isLoggedIn = true
            self.userID = Auth.auth().currentUser?.uid
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
            self.userID = Auth.auth().currentUser?.uid
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        do {
            try FirebaseAuthManager.shared.signOut()
            self.isLoggedIn = false
            self.userID = nil
            email = ""
            password = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

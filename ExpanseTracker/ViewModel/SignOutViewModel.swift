//
//  SignOutViewModel.swift
//  ExpanseTracker
//
//  Created by KPIT on 29/07/25.
//


import Foundation

@MainActor
final class SignOutViewModel: ObservableObject {
    
    func signOut() throws {
        try FirebaseAuthManager.shared.signOut()
    }
    
    func resetPassword() async throws {
        
        let authUser = try FirebaseAuthManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        
        try await FirebaseAuthManager.shared.resetPasword(email: email)
    }
    
    func updatePassword() async throws {
        let password = "PAss123"
        
        try await FirebaseAuthManager.shared.updatePassword(password: password)
    }
    
    func updateEmail() async throws {
        let email = "abcdw@yopmail.com"
        
        try await FirebaseAuthManager.shared.updateEmail(email: email)
    }
}

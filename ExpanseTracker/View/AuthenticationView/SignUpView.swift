//
//  SignUpView.swift
//  ExpanseTracker
//
//  Created by KPIT on 29/07/25.
//

import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    
    @EnvironmentObject var viewModel: SignInViewModel
    
    var body: some View {
        
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            
            TextField("Enter Email", text: $viewModel.email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textFieldStyle(AuthTextFieldStyle())
            
            SecureField("Enter Password", text: $viewModel.password)
                .textContentType(.newPassword)
                .textFieldStyle(AuthTextFieldStyle())
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            
            Button("Create Account") {
                Task {
                    await viewModel.signUp()
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SignUpView()
}

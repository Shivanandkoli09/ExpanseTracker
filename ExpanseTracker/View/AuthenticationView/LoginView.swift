//
//  LoginView.swift
//  ExpanseTracker
//
//  Created by KPIT on 29/07/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var viewModel: SignInViewModel
    @State private var isShowingSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Login")
                    .font(.largeTitle)
                    .bold()
                
                TextField("Enter Email", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textFieldStyle(AuthTextFieldStyle())
                
                SecureField("Enter Password", text: $viewModel.password)
                    .textFieldStyle(AuthTextFieldStyle())
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                Button("Login") {
                    Task {
                        await viewModel.signIn()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Don't have an account? Sign Up") {
                    isShowingSignUp = true
                }
                .padding(.top)
                .font(.footnote)
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $isShowingSignUp) {
                SignUpView()
                    .environmentObject(viewModel)
            }
        }
        
    }
}



#Preview {
    LoginView()
}

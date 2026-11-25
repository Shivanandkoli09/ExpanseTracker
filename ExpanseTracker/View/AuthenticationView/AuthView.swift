//
//  AuthView.swift
//  ExpanseTracker
//
//  Single screen for sign in and account creation.
//

import SwiftUI

struct AuthView: View {

    @EnvironmentObject private var viewModel: SignInViewModel
    @FocusState private var focusedField: AuthField?
    @State private var isShowingForgotPassword = false

    private var isSignUp: Bool { viewModel.mode == .signUp }

    var body: some View {
        ZStack {
            AuthBackground()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    formCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .animation(.spring(duration: 0.35), value: viewModel.mode)
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
        .sensoryFeedback(.error, trigger: viewModel.errorMessage) { _, new in new != nil }
        .sensoryFeedback(.selection, trigger: viewModel.mode)
        .sheet(isPresented: $isShowingForgotPassword) {
            ForgotPasswordView(initialEmail: viewModel.trimmedEmail)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            OrbitLogo()

            Text(isSignUp ? "Start your money story" : "\(Self.greeting) 👋")
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)

            Text(isSignUp
                 ? "Track spending effortlessly. Our AI sorts every rupee for you."
                 : "Welcome back to MyMoney. Let's see where your money went.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            AuthModePicker(selection: viewModel.mode) { mode in
                viewModel.switchMode(to: mode)
                focusedField = nil
            }

            if isSignUp {
                AuthTextField(
                    title: "Your name",
                    icon: "person",
                    text: $viewModel.name,
                    field: .name,
                    focus: $focusedField,
                    contentType: .name,
                    capitalization: .words
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .onSubmit { focusedField = .email }
            }

            AuthTextField(
                title: "Email address",
                icon: "envelope",
                text: $viewModel.email,
                field: .email,
                focus: $focusedField,
                contentType: .emailAddress,
                keyboard: .emailAddress,
                isValid: viewModel.email.isEmpty ? nil : viewModel.isEmailValid
            )
            .onSubmit { focusedField = .password }

            VStack(alignment: .leading, spacing: 10) {
                AuthTextField(
                    title: "Password",
                    icon: "lock",
                    text: $viewModel.password,
                    field: .password,
                    focus: $focusedField,
                    isSecure: true,
                    contentType: isSignUp ? .newPassword : .password,
                    submitLabel: isSignUp ? .next : .go
                )
                .onSubmit {
                    if isSignUp { focusedField = nil } else { submit() }
                }

                if isSignUp {
                    PasswordStrengthView(strength: viewModel.passwordStrength)
                        .transition(.opacity)
                } else {
                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            isShowingForgotPassword = true
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.primary)
                    }
                }
            }

            if isSignUp {
                goalPicker
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let error = viewModel.errorMessage {
                AuthErrorBanner(message: error)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            PrimaryButton(
                title: isSignUp ? "Create Account" : "Sign In",
                isLoading: viewModel.isLoading,
                isEnabled: viewModel.canSubmit,
                action: submit
            )
            .padding(.top, 4)

            footer
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 20, y: 10)
        )
    }

    private var goalPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 4) {
                Text("What are you saving for?")
                    .font(.subheadline.weight(.semibold))
                Text("Optional")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(SavingGoal.allCases) { goal in
                    GoalChip(goal: goal, isSelected: viewModel.savingGoal == goal) {
                        viewModel.savingGoal = (viewModel.savingGoal == goal) ? nil : goal
                    }
                }
            }
            .sensoryFeedback(.selection, trigger: viewModel.savingGoal)

            Text("We'll tailor your insights around this goal.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text(isSignUp ? "Already have an account?" : "New to MyMoney?")
                .foregroundStyle(.secondary)
            Button(isSignUp ? "Sign in" : "Create one") {
                viewModel.switchMode(to: isSignUp ? .signIn : .signUp)
            }
            .fontWeight(.semibold)
            .foregroundStyle(Brand.primary)
        }
        .font(.footnote)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func submit() {
        focusedField = nil
        Task { await viewModel.submit() }
    }

    private static var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Hello, night owl"
        }
    }
}

// MARK: - Forgot Password

struct ForgotPasswordView: View {
    @EnvironmentObject private var viewModel: SignInViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email: String
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var didSend = false
    @FocusState private var focusedField: AuthField?

    init(initialEmail: String) {
        _email = State(initialValue: initialEmail)
    }

    private var isEmailValid: Bool {
        email.trimmingCharacters(in: .whitespaces)
            .range(of: #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#, options: .regularExpression) != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: didSend ? "envelope.open.badge.clock" : "key.horizontal.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Brand.gradient)
                    .symbolEffect(.bounce, value: didSend)
                    .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(didSend ? "Check your inbox" : "Reset your password")
                        .font(.title2.weight(.bold))
                    Text(didSend
                         ? "We sent a reset link to \(email). It may take a minute to arrive."
                         : "Enter the email you signed up with and we'll send you a reset link.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if !didSend {
                    AuthTextField(
                        title: "Email address",
                        icon: "envelope",
                        text: $email,
                        field: .email,
                        focus: $focusedField,
                        contentType: .emailAddress,
                        keyboard: .emailAddress,
                        submitLabel: .send,
                        isValid: email.isEmpty ? nil : isEmailValid
                    )
                    .onSubmit(send)

                    if let errorMessage {
                        AuthErrorBanner(message: errorMessage)
                    }
                }

                PrimaryButton(
                    title: didSend ? "Back to Sign In" : "Send Reset Link",
                    isLoading: isSending,
                    isEnabled: didSend || isEmailValid
                ) {
                    didSend ? dismiss() : send()
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .animation(.spring(duration: 0.35), value: didSend)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if email.isEmpty { focusedField = .email }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sensoryFeedback(.success, trigger: didSend) { _, new in new }
    }

    private func send() {
        guard isEmailValid, !isSending else { return }
        focusedField = nil
        isSending = true
        errorMessage = nil
        Task {
            let error = await viewModel.sendPasswordReset(to: email)
            isSending = false
            if let error {
                errorMessage = error
            } else {
                didSend = true
            }
        }
    }
}

#Preview("Auth") {
    AuthView()
        .environmentObject(SignInViewModel())
}

//
//  ProfileView.swift
//  ExpanseTracker
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject private var authViewModel: SignInViewModel
    @EnvironmentObject private var transactionManager: TransactionManager
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var appLock: AppLockManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var viewModel = ProfileViewModel()

    @AppStorage(NotificationManager.Keys.reminderEnabled) private var reminderEnabled = true
    @AppStorage(NotificationManager.Keys.reminderHour) private var reminderHour = 20
    @AppStorage(NotificationManager.Keys.reminderMinute) private var reminderMinute = 0
    @State private var notificationsDenied = false

    @State private var isEditingName = false
    @State private var draftName = ""
    @State private var isConfirmingSignOut = false
    @State private var isShowingDeleteAccount = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                }
                .listRowBackground(Color.clear)

                goalSection
                reminderSection
                securitySection
                dataSection
                accountSection
                aboutSection

                Section {
                    Button(role: .destructive) {
                        isShowingDeleteAccount = true
                    } label: {
                        Label("Delete Account", systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Permanently deletes your account and all of your data.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await refreshNotificationStatus()
            }
            .alert("Your name", isPresented: $isEditingName) {
                TextField("Your name", text: $draftName)
                    .textInputAutocapitalization(.words)
                Button("Save") {
                    Task {
                        if await viewModel.updateName(draftName) {
                            authViewModel.refreshUser()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert(
                viewModel.message?.title ?? "",
                isPresented: Binding(
                    get: { viewModel.message != nil },
                    set: { if !$0 { viewModel.message = nil } }
                ),
                presenting: viewModel.message
            ) { _ in
                Button("OK") {}
            } message: { message in
                Text(message.body)
            }
            .confirmationDialog("Sign out of MyMoney?", isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    authViewModel.logout()
                }
            } message: {
                Text("Your data stays safe in the cloud. Sign in again any time.")
            }
            .sheet(isPresented: $isShowingDeleteAccount) {
                DeleteAccountView(viewModel: viewModel)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 14) {
            Text(viewModel.initials)
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(Circle().fill(Brand.gradient))
                .shadow(color: Brand.primary.opacity(0.35), radius: 12, y: 6)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Text(viewModel.displayName)
                        .font(.title2.weight(.bold))
                    Button {
                        draftName = viewModel.name
                        isEditingName = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Edit name")
                }
                Text(viewModel.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                statTile(value: "\(transactionManager.transactions.count)", label: "Transactions")
                statTile(value: viewModel.memberSince?.formatted(.dateTime.month(.abbreviated).year()) ?? "—",
                         label: "Member since")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private func statTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Saving Goal

    private var goalSection: some View {
        Section {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(SavingGoal.allCases) { goal in
                    GoalChip(goal: goal, isSelected: profileStore.savingGoal == goal) {
                        let isSame = profileStore.savingGoal == goal
                        // A different goal usually means a different amount, so its target resets.
                        profileStore.setSavingGoal(isSame ? nil : goal, target: nil)
                    }
                }
            }
            .padding(.vertical, 6)
            .sensoryFeedback(.selection, trigger: profileStore.savingGoal)
        } header: {
            Text("Saving goal")
        } footer: {
            if let goal = profileStore.savingGoal {
                Text("Insights will be tailored to your \(goal.title) goal \(goal.emoji)")
            } else {
                Text("Pick what you're saving for and we'll tailor your insights to it.")
            }
        }
    }

    // MARK: - Reminders

    private var reminderSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { reminderEnabled },
                set: { newValue in
                    reminderEnabled = newValue
                    Task { await reminderSettingsChanged() }
                }
            )) {
                Label("Daily reminder", systemImage: "bell.badge")
            }

            if reminderEnabled {
                DatePicker(selection: reminderTime, displayedComponents: .hourAndMinute) {
                    Label("Remind me at", systemImage: "clock")
                }
            }
        } header: {
            Text("Reminders")
        } footer: {
            if reminderEnabled && notificationsDenied {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Notifications are turned off for MyMoney in iOS Settings.")
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .font(.footnote.weight(.semibold))
                }
            } else {
                Text("A gentle nudge to log your spending — skipped on days you've already added something.")
            }
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let components = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderHour = components.hour ?? 20
                reminderMinute = components.minute ?? 0
                Task { await reminderSettingsChanged() }
            }
        )
    }

    private func reminderSettingsChanged() async {
        await NotificationManager.shared.applySavedReminderSettings()
        await refreshNotificationStatus()
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await NotificationManager.shared.authorizationStatus() == .denied
    }

    // MARK: - Security

    @ViewBuilder
    private var securitySection: some View {
        if appLock.isAvailable {
            Section {
                Toggle(isOn: Binding(
                    get: { appLock.isEnabled },
                    set: { newValue in Task { await appLock.setEnabled(newValue) } }
                )) {
                    Label("Lock with \(appLock.methodName)", systemImage: appLock.methodIcon)
                }
            } header: {
                Text("Security")
            } footer: {
                Text("Require \(appLock.methodName) when you open MyMoney. Your balances are also hidden in the app switcher.")
            }
        }
    }

    // MARK: - Your Data

    private var dataSection: some View {
        Section {
            ShareLink(
                item: TransactionsCSV(transactions: transactionManager.transactions),
                preview: SharePreview("MyMoney transactions", image: Image(systemName: "tablecells"))
            ) {
                Label("Export Transactions (CSV)", systemImage: "square.and.arrow.up")
            }
            .disabled(transactionManager.transactions.isEmpty)
        } header: {
            Text("Your data")
        } footer: {
            Text("Download all your transactions as a spreadsheet you can open in Numbers, Excel or Google Sheets.")
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("Account") {
            Button {
                Task { await viewModel.sendPasswordReset() }
            } label: {
                Label("Change Password", systemImage: "key")
            }

            Button {
                isConfirmingSignOut = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section("About") {
            if let url = AppLinks.privacyPolicy {
                Link(destination: url) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
            if let url = AppLinks.helpAndSupport {
                Link(destination: url) {
                    Label("Help & FAQ", systemImage: "questionmark.circle")
                }
            }
            if let url = AppLinks.termsOfUse {
                Link(destination: url) {
                    Label("Terms of Use", systemImage: "doc.text")
                }
            }
            if let email = AppLinks.supportEmail, let url = URL(string: "mailto:\(email)") {
                Link(destination: url) {
                    Label("Contact Support", systemImage: "envelope")
                }
            }
            LabeledContent {
                Text(Self.appVersion)
            } label: {
                Label("Version", systemImage: "info.circle")
            }
        }
    }

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Delete Account

struct DeleteAccountView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var password = ""
    @State private var errorMessage: String?
    @FocusState private var focusedField: AuthField?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.red)
                        Text("Delete your account?")
                            .font(.title2.weight(.bold))
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("This permanently removes:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        bullet("Every transaction you've tracked", icon: "list.bullet.rectangle")
                        bullet("Your profile and saving goal", icon: "person.crop.circle")
                        bullet("MyMoney data on this device", icon: "iphone")
                    }

                    Text("This can't be undone.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)

                    AuthTextField(
                        title: "Enter your password to confirm",
                        icon: "lock",
                        text: $password,
                        field: .password,
                        focus: $focusedField,
                        isSecure: true,
                        contentType: .password,
                        submitLabel: .done
                    )

                    if let errorMessage {
                        AuthErrorBanner(message: errorMessage)
                    }

                    Button(role: .destructive, action: delete) {
                        ZStack {
                            Text("Delete Permanently")
                                .font(.headline)
                                .opacity(viewModel.isDeleting ? 0 : 1)
                            if viewModel.isDeleting {
                                ProgressView().tint(.white)
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(password.isEmpty ? 0.4 : 1))
                        )
                    }
                    .buttonStyle(PressableButtonStyle())
                    .disabled(password.isEmpty || viewModel.isDeleting)
                }
                .padding(24)
                .animation(.easeInOut(duration: 0.2), value: errorMessage)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(viewModel.isDeleting)
                }
            }
        }
        .interactiveDismissDisabled(viewModel.isDeleting)
        .sensoryFeedback(.error, trigger: errorMessage) { _, new in new != nil }
    }

    private func bullet(_ text: String, icon: String) -> some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.red)
        }
        .font(.subheadline)
    }

    private func delete() {
        focusedField = nil
        errorMessage = nil
        Task {
            errorMessage = await viewModel.deleteAccount(password: password)
        }
    }
}

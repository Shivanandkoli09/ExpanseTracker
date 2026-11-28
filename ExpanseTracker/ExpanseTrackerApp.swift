//
//  ExpanseTrackerApp.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 09/06/25.
//

import SwiftUI
import CoreData
import Firebase

@main
struct ExpanseTrackerApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    private let persistence = PersistenceController.shared
    @StateObject private var authViewModel = SignInViewModel()
    @StateObject private var appLock = AppLockManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn, let userID = authViewModel.userID {
                    SignedInRoot(userID: userID, context: persistence.container.viewContext)
                        .id(userID)
                        .overlay {
                            if appLock.isLocked {
                                LockScreenView()
                                    .transition(.opacity)
                            }
                        }
                } else {
                    AuthView()
                        .transition(.opacity)
                }
            }
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .environmentObject(authViewModel)
            .environmentObject(appLock)
            .overlay {
                // Hide balances in the app switcher snapshot.
                if scenePhase != .active && authViewModel.isLoggedIn && !appLock.isLocked {
                    PrivacyCoverView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoggedIn)
            .animation(.easeInOut(duration: 0.2), value: appLock.isLocked)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { appLock.lockIfEnabled() }
            }
            .onChange(of: authViewModel.userID) { oldValue, newValue in
                if oldValue != nil, newValue == nil {
                    persistence.deleteAllTransactions()
                    appLock.reset()
                    Task { await NotificationManager.shared.cancelDailyReminder() }
                }
            }
        }
    }
}

/// Owns the per-user managers so they are created once per sign-in,
/// not on every re-render of the app's root view.
private struct SignedInRoot: View {
    @StateObject private var transactionManager: TransactionManager
    @StateObject private var profileStore: UserProfileStore
    @StateObject private var groupsStore: GroupsStore

    init(userID: String, context: NSManagedObjectContext) {
        _groupsStore = StateObject(wrappedValue: GroupsStore(userId: userID))
        _profileStore = StateObject(wrappedValue: UserProfileStore(userId: userID))
        _transactionManager = StateObject(wrappedValue: TransactionManager(
            context: context,
            remote: FirestoreTransactionManager(userId: userID)
        ))
    }

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environmentObject(transactionManager)
        .environmentObject(profileStore)
        .environmentObject(groupsStore)
        .task {
            // Ask only once the user is signed in and has context for why.
            await NotificationManager.shared.applySavedReminderSettings()
        }
        .onChange(of: transactionManager.transactions) { _, transactions in
            Task { await NotificationManager.shared.updateActivity(transactions: transactions) }
        }
        // Your share of group expenses counts as personal spending.
        .onChange(of: groupsStore.groups) { _, _ in syncGroupShares() }
        .onChange(of: groupsStore.hasLoaded) { _, _ in syncGroupShares() }
    }

    private func syncGroupShares() {
        guard groupsStore.hasLoaded else { return }
        transactionManager.reconcileGroupShares(GroupShareSync.desiredTransactions(for: groupsStore.groups))
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

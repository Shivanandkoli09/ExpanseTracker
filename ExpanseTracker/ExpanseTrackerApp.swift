//
//  ExpanseTrackerApp.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import SwiftUI
import CoreData
import Firebase

@main
struct ExpanseTrackerApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    private let persistence = PersistenceController.shared
    @StateObject private var authViewModel = SignInViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn, let userID = authViewModel.userID {
                    SignedInRoot(userID: userID, context: persistence.container.viewContext)
                        .id(userID)
                } else {
                    AuthView()
                        .transition(.opacity)
                }
            }
            .environment(\.managedObjectContext, persistence.container.viewContext)
            .environmentObject(authViewModel)
            .animation(.easeInOut(duration: 0.3), value: authViewModel.isLoggedIn)
            .onChange(of: authViewModel.userID) { oldValue, newValue in
                if oldValue != nil, newValue == nil {
                    persistence.deleteAllTransactions()
                }
            }
        }
    }
}

/// Owns the per-user managers so they are created once per sign-in,
/// not on every re-render of the app's root view.
private struct SignedInRoot: View {
    @StateObject private var transactionManager: TransactionManager

    init(userID: String, context: NSManagedObjectContext) {
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
        .task {
            // Ask only once the user is signed in and has context for why.
            await NotificationManager.shared.applySavedReminderSettings()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

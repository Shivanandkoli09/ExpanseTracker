//
//  ExpanseTrackerApp.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import SwiftUI
import Firebase

@main
struct ExpanseTrackerApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let persistenceController = PersistenceController()
    @StateObject private var authviewModel = SignInViewModel()
    
    var body: some Scene {
        WindowGroup {
            let context = persistenceController.container.viewContext
            let transactionManager = TransactionManager(context: context)
            
            Group {
                if authviewModel.isLoggedIn {
                    NavigationStack {
                        HomeView()
                            .environment(\.managedObjectContext, context)
                            .environmentObject(transactionManager)
                            .environmentObject(authviewModel)
                    }
                } else {
                    NavigationStack {
                        LoginView()
                            .environmentObject(authviewModel)
                    }
                }
            }
            .environmentObject(transactionManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        return true
    }
}

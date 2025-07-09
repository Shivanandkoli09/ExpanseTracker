//
//  ExpanseTrackerApp.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import SwiftUI

@main
struct ExpanseTrackerApp: App {
    let persistenceController = PersistenceController()
    var body: some Scene {
        WindowGroup {
            let context = persistenceController.container.viewContext
            let transactionManager = TransactionManager(context: context)
            NavigationStack {
                HomeView()
                    .environment(\.managedObjectContext, context)
                    .environmentObject(transactionManager)
            }
            .environmentObject(transactionManager)
        }
    }
}

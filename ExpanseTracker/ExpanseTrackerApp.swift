//
//  ExpanseTrackerApp.swift
//  ExpanseTracker
//
//  Created by KPIT on 09/06/25.
//

import SwiftUI

@main
struct ExpanseTrackerApp: App {
    @StateObject private var transactionManager = TransactionManager()
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(transactionManager)
        }
    }
}

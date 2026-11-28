//
//  AppRouter.swift
//  ExpanseTracker
//
//  Single navigation path for the signed-in app. Every push goes through
//  here and every destination is declared once, at the root of the stack.
//

import SwiftUI

enum AppRoute: Hashable {
    case groups
    case group(id: String)
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func open(_ route: AppRoute) {
        path.append(route)
    }

    /// Opens a group from anywhere, with the Groups list underneath it so Back makes sense.
    func openGroup(_ id: String) {
        if path.last == .group(id: id) { return }
        path = [.groups, .group(id: id)]
    }
}

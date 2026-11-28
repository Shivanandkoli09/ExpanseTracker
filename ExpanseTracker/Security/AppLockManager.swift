//
//  AppLockManager.swift
//  ExpanseTracker
//
//  Optional Face ID / Touch ID / passcode lock for the app.
//

import Foundation
import LocalAuthentication

@MainActor
final class AppLockManager: ObservableObject {

    static let enabledKey = "appLockEnabled"

    @Published private(set) var isEnabled: Bool
    @Published private(set) var isLocked: Bool
    @Published private(set) var isAuthenticating = false

    init() {
        let enabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        isEnabled = enabled
        isLocked = enabled
    }

    /// "Face ID", "Touch ID" or "Passcode", for labels.
    var methodName: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        default:       return "Passcode"
        }
    }

    var methodIcon: String {
        switch methodName {
        case "Face ID":  return "faceid"
        case "Touch ID": return "touchid"
        case "Optic ID": return "opticid"
        default:         return "lock.fill"
        }
    }

    /// The device must have at least a passcode for the lock to make sense.
    var isAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// Turning the lock on asks for authentication first, so users can't lock themselves out.
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            guard await authenticate(reason: "Confirm to turn on app lock") else { return }
        }
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.enabledKey)
    }

    func lockIfEnabled() {
        if isEnabled { isLocked = true }
    }

    func unlock() async {
        if await authenticate(reason: "Unlock MyMoney") {
            isLocked = false
        }
    }

    /// Called on sign-out: the lock belongs to the signed-in session.
    func reset() {
        isEnabled = false
        isLocked = false
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
    }

    private func authenticate(reason: String) async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        do {
            // Falls back to the device passcode if biometrics fail or aren't set up.
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}

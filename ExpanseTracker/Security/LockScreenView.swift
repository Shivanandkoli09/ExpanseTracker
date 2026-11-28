//
//  LockScreenView.swift
//  ExpanseTracker
//

import SwiftUI

struct LockScreenView: View {
    @EnvironmentObject private var lock: AppLockManager

    var body: some View {
        ZStack {
            AuthBackground()

            VStack(spacing: 20) {
                Spacer()
                OrbitLogo()
                VStack(spacing: 6) {
                    Text("MyMoney is locked")
                        .font(.title2.weight(.bold))
                    Text("Your finances stay private.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                PrimaryButton(
                    title: "Unlock with \(lock.methodName)",
                    isLoading: lock.isAuthenticating
                ) {
                    Task { await lock.unlock() }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .task {
            await lock.unlock()
        }
    }
}

/// Hides balances in the app switcher snapshot.
struct PrivacyCoverView: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Brand.gradient)
                .frame(width: 72, height: 72)
                .overlay(
                    Image(systemName: "indianrupeesign")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .ignoresSafeArea()
    }
}

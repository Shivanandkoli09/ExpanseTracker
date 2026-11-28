//
//  NotificationManager.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 10/06/26.
//

import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let reminderID = "daily_expense_reminder"

    // MARK: - Saved settings (shared with the Profile screen via @AppStorage)

    enum Keys {
        static let reminderEnabled = "reminderEnabled"
        static let reminderHour = "reminderHour"
        static let reminderMinute = "reminderMinute"
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            Keys.reminderEnabled: true,
            Keys.reminderHour: 20,
            Keys.reminderMinute: 0
        ])
    }

    // MARK: - Permission

    @discardableResult
    func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Daily Reminder

    /// Applies whatever the user saved in Profile. Safe to call on every launch.
    func applySavedReminderSettings() async {
        Self.registerDefaults()
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: Keys.reminderEnabled) else {
            cancelDailyReminder()
            return
        }
        guard await requestPermission() else { return }
        scheduleDailyReminder(
            hour: defaults.integer(forKey: Keys.reminderHour),
            minute: defaults.integer(forKey: Keys.reminderMinute)
        )
    }

    func scheduleDailyReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Expense Reminder 💰"
        content.body = "Don't forget to track today's expenses."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let request = UNNotificationRequest(
            identifier: reminderID,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        )
        // Same identifier replaces any previously scheduled reminder.
        center.add(request) { error in
            if let error { print("❌ Notification Error:", error.localizedDescription) }
        }
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}

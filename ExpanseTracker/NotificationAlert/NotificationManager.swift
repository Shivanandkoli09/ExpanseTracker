//
//  NotificationManager.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 10/06/26.
//

import Foundation
import UserNotifications

/// Smart daily reminder: one notification per day at the user's chosen time,
/// skipped on days they've already logged something.
final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    private let center = UNUserNotificationCenter.current()
    private let idPrefix = "daily_expense_reminder"
    /// Scheduled ahead as one-off notifications so today's can be skipped individually.
    private let daysAhead = 14
    /// Whether the user has logged a transaction dated today. Updated by the app.
    private var loggedToday = false

    private let messages = [
        "Anything spent today? Logging it takes 5 seconds. 💰",
        "Quick check-in: add today's expenses before you forget.",
        "Keep your streak going 🔥 Log today's spending.",
        "Your future self will thank you. Track today's expenses."
    ]

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

    /// Call when transactions change. Reschedules only if "logged today" flipped.
    func updateActivity(transactions: [Transaction]) async {
        let logged = transactions.contains { Calendar.current.isDateInToday($0.date) }
        guard logged != loggedToday else { return }
        loggedToday = logged
        await applySavedReminderSettings()
    }

    /// Applies whatever the user saved in Profile. Safe to call on every launch.
    func applySavedReminderSettings() async {
        Self.registerDefaults()
        let defaults = UserDefaults.standard

        guard defaults.bool(forKey: Keys.reminderEnabled) else {
            await cancelDailyReminder()
            return
        }
        guard await requestPermission() else { return }
        await scheduleReminders(
            hour: defaults.integer(forKey: Keys.reminderHour),
            minute: defaults.integer(forKey: Keys.reminderMinute)
        )
    }

    func cancelDailyReminder() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func scheduleReminders(hour: Int, minute: Int) async {
        await cancelDailyReminder()

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fireDate = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day),
                  fireDate > now else { continue }
            if offset == 0 && loggedToday { continue }

            let content = UNMutableNotificationContent()
            content.title = "MyMoney"
            content.body = messages[offset % messages.count]
            content.sound = .default

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let request = UNNotificationRequest(
                identifier: "\(idPrefix)-\(offset)-\(Int(fireDate.timeIntervalSince1970))",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }
}

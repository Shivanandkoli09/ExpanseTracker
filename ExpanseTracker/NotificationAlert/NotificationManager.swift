//
//  NotificationManager.swift
//  ExpanseTracker
//
//  Created by Shivanand Koli on 10/06/26.
//

import Foundation
import UserNotifications

import Foundation
import UserNotifications

final class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    // MARK: - Request Permission

    func requestPermission() {

        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in

            if let error = error {
                print("❌ Permission Error:", error.localizedDescription)
                return
            }

            if granted {
                print("✅ Notification Permission Granted")
            } else {
                print("❌ Notification Permission Denied")
            }
        }
    }

    // MARK: - Daily Expense Reminder

    func scheduleDailyExpenseReminder() {

        let content = UNMutableNotificationContent()

        content.title = "Expense Reminder 💰"
        content.body = "Don't forget to track today's expenses."
        content.sound = .default

        var dateComponents = DateComponents()

        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: "daily_expense_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in

            if let error = error {
                print("❌ Notification Error:", error.localizedDescription)
            } else {
                print("✅ Daily Reminder Scheduled")
            }
        }
    }

    // MARK: - Debug Pending Notifications

    func printPendingNotifications() {

        UNUserNotificationCenter.current()
            .getPendingNotificationRequests { requests in

                print("📢 Pending Notifications Count: \(requests.count)")

                for request in requests {
                    print("📢 Notification ID: \(request.identifier)")
                }
            }
    }

    // MARK: - Clear Notifications

    func clearNotifications() {

        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()

        print("🗑 Notifications Cleared")
    }
}

//
//  NotificationManager.swift
//  Railmates
//
//  Created by Amir Kozarcanin on 2026-08-02.
//

import Foundation
import Combine
import UIKit
import UserNotifications
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var deviceToken: String?
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission Request
    
    func requestPermission() async throws -> Bool {
        let settings = await notificationCenter.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
            return true
            
        case .notDetermined:
            do {
                let granted = try await notificationCenter.requestAuthorization(
                    options: [.alert, .badge, .sound]
                )
                isAuthorized = granted
                
                if granted {
                    await registerForRemoteNotifications()
                }
                
                return granted
            } catch {
                print("Error requesting notification permission: \(error)")
                throw error
            }
            
        case .denied:
            isAuthorized = false
            return false
            
        @unknown default:
            return false
        }
    }
    
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleHappeningReminder(for happening: Happening) {
        guard let happeningId = happening.id else { return }
        
        // Schedule notification 1 hour before event
        let reminderTime = happening.dateTime.addingTimeInterval(-3600) // 1 hour before
        
        // Don't schedule if it's in the past
        guard reminderTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Event Starting Soon!"
        content.body = "\(happening.title) starts in 1 hour in \(happening.city)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["happeningId": happeningId, "type": "reminder"]
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderTime
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(
            identifier: "happening-\(happeningId)-reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("✅ Scheduled reminder for \(happening.title)")
            }
        }
    }
    
    func cancelHappeningReminder(happeningId: String) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["happening-\(happeningId)-reminder"]
        )
    }
    
    func scheduleNewHappeningNotification(happening: Happening, forCity city: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Event in \(city)!"
        content.body = "\(happening.title) - \(happening.dateTime.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["happeningId": happening.id ?? "", "type": "new_event"]
        
        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "new-happening-\(happening.id ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending new happening notification: \(error)")
            }
        }
    }
    
    func notifyCreatorOfNewAttendee(happening: Happening, attendeeName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Someone Joined Your Event!"
        content.body = "\(attendeeName) is joining \(happening.title)"
        content.sound = .default
        content.userInfo = ["happeningId": happening.id ?? "", "type": "new_attendee"]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "attendee-\(happening.id ?? "")-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending attendee notification: \(error)")
            }
        }
    }
    
    // MARK: - Badge Management
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    func setBadge(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle different notification types
        if let happeningId = userInfo["happeningId"] as? String {
            print("User tapped notification for happening: \(happeningId)")
            // TODO: Navigate to happening detail
            // You can post a notification to handle navigation
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenHappening"),
                object: nil,
                userInfo: ["happeningId": happeningId]
            )
        }
        
        completionHandler()
    }
}

// MARK: - MessagingDelegate (for FCM)

#if canImport(FirebaseMessaging)
extension NotificationManager: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token: \(fcmToken ?? "nil")")
        self.deviceToken = fcmToken
        
        // TODO: Send token to your server or store in Firestore
        // This allows you to send push notifications to this device
    }
}
#endif

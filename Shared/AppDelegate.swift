//
//  AppDelegate.swift
//  valta
//
//  Handles app lifecycle and push notification registration/delivery.
//
//  Created by vlad on 05/12/2025.
//

#if os(macOS)
import AppKit
import UserNotifications
import FirebaseMessaging
import Firebase
import FirebaseFirestore
import Sparkle
import MPLemons

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(-1, forKey: "AppleAccentColor")

        // Setup notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Init Firebase
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        FirebaseApp.configure()

        // Initialize Sparkle
        SparkleUpdateManager.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Prevent immediate termination to allow animation to finish and gRPC to close
        Task {
            // Wait for window animation (0.5s)
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Clean up Firestore to prevent gRPC timeout
            // We use a separate Task to ensure it doesn't block if it hangs, though terminate() is usually fast
            try? await Firestore.firestore().terminate() // Ignore errors on shutdown to avoid blocking termination

            // Quit the app gracefully
            NSApplication.shared.terminate(nil)
        }
        return false
    }

    // MARK: - Remote Notification Registration

    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        // Manually fetch FCM token (workaround for macOS where delegate doesn't always fire)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await NotificationService.shared.retrieveFCMToken()
        }
    }

    func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Reload data when notification arrives
        handleNotificationData(userInfo: userInfo)

        // Show notification even when app is in foreground
        #if os(macOS)
        if #available(macOS 11.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.sound, .badge])
        }
        #else
        completionHandler([.banner, .sound, .badge])
        #endif
    }

    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Bring app to foreground
        NSApp.activate(ignoringOtherApps: true)

        // Reload data and handle notification tap
        handleNotificationData(userInfo: userInfo)
        handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }

    // MARK: - Notification Handling

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let type = userInfo["type"] as? String,
              let activityIdString = userInfo["activityId"] as? String,
              let activityId = UUID(uuidString: activityIdString) else {
            return
        }

        print("📱 Handling notification tap - Type: \(type), Activity ID: \(activityId)")

    }

    private func handleNotificationData(userInfo: [AnyHashable: Any]) {
        // Trigger data reload for all activity-related notifications
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "activity_assigned", "activity_started", "activity_completed", "activity_canceled",
                 "completion_requested", "completion_approved", "completion_rejected":
                Task {
                    await DataManager.shared.loadData()
                }
            default:
                break
            }
        }
    }
}
#endif

#if os(iOS) || os(visionOS) || os(tvOS)
import UIKit
import UserNotifications
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setup notification center delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // MARK: - Remote Notification Registration

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Registered for remote notifications")
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("📬 Received notification in foreground: \(userInfo)")

        // Reload data when notification arrives
        handleNotificationData(userInfo: userInfo)

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification tap (app will be brought to foreground automatically on iOS)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("👆 User tapped notification: \(userInfo)")

        // Reload data and handle notification tap
        handleNotificationData(userInfo: userInfo)
        handleNotificationTap(userInfo: userInfo)

        completionHandler()
    }

    // MARK: - Notification Handling

    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let type = userInfo["type"] as? String,
              let activityIdString = userInfo["activityId"] as? String,
              let activityId = UUID(uuidString: activityIdString) else {
            return
        }

        print("📱 Handling notification tap - Type: \(type), Activity ID: \(activityId)")
    }

    private func handleNotificationData(userInfo: [AnyHashable: Any]) {
        // Trigger data reload for all activity-related notifications
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "activity_assigned", "activity_started", "activity_completed", "activity_canceled",
                 "completion_requested", "completion_approved", "completion_rejected":
                Task {
                    await DataManager.shared.loadData()
                }
            default:
                break
            }
        }
    }
}
#endif

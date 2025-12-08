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

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        UserDefaults.standard.set(-1, forKey: "AppleAccentColor")
        
        // Setup notification center delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // MARK: - Remote Notification Registration
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("✅ Registered for remote notifications")
        Messaging.messaging().apnsToken = deviceToken
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
        print("📬 Received notification in foreground: \(userInfo)")
        
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
        print("👆 User tapped notification: \(userInfo)")
        
        // Handle notification tap - navigate to relevant screen
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
        
        // TODO: Navigate to relevant screen based on notification type
        // This will be implemented when we have navigation infrastructure
        // For now, we'll just log the action
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
        print("👆 User tapped notification: \(userInfo)")
        
        // Handle notification tap - navigate to relevant screen
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
        
        // TODO: Navigate to relevant screen based on notification type
        // This will be implemented when we have navigation infrastructure
        // For now, we'll just log the action
    }
}
#endif



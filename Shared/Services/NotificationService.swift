//
//  NotificationService.swift
//  Shared
//
//  Handles Firebase Cloud Messaging (FCM) token management and notification permissions.
//  Manages FCM token registration, storage, and refresh.
//
//  Created by vlad on 2025-12-05.
//

import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseAuth
import Observation

@Observable
@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    // MARK: - Properties
    
    var fcmToken: String?
    var isPermissionGranted: Bool = false
    var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    private override init() {
        super.init()
        // Setup FCM token delegate
        Messaging.messaging().delegate = self
    }
    
    // MARK: - Permission Management
    
    /// Requests notification permissions from the user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isPermissionGranted = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            // Update permission status
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Checks current notification permission status
    func checkPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.notificationPermissionStatus = settings.authorizationStatus
            self.isPermissionGranted = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - FCM Token Management
    
    /// Registers for remote notifications (call this after permission is granted)
    func registerForRemoteNotifications() async {
        #if os(iOS) || os(visionOS) || os(tvOS)
        await UIApplication.shared.registerForRemoteNotifications()
        #elseif os(macOS)
        await NSApplication.shared.registerForRemoteNotifications()
        #endif
        
        // Get FCM token
        await retrieveFCMToken()
    }
    
    /// Retrieves the current FCM token
    func retrieveFCMToken() async {
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
            }
            print("FCM Token: \(token)")
            
            // Upload token to backend if user is authenticated
            if let userId = Auth.auth().currentUser?.uid {
                await uploadFCMToken(token, userId: userId)
            }
        } catch {
            print("Error retrieving FCM token: \(error.localizedDescription)")
        }
    }
    
    /// Uploads FCM token to Firestore/backend
    private func uploadFCMToken(_ token: String, userId: String) async {
        // TODO: Implement Firestore upload
        // For now, we'll prepare the structure
        // This will be implemented when we add Firestore dependency
        
        print("📤 Uploading FCM token for user: \(userId)")
        print("   Token: \(token.prefix(20))...")
        
        // Placeholder for Firestore integration
        // await FirestoreService.shared.saveFCMToken(token, for: userId)
    }
    
    /// Deletes FCM token from backend (on logout)
    func deleteFCMToken(userId: String) async {
        print("🗑️ Deleting FCM token for user: \(userId)")
        
        // Placeholder for Firestore integration
        // await FirestoreService.shared.deleteFCMToken(for: userId)
    }
    
    /// Subscribes to team-specific notification topics
    func subscribeToTeamNotifications(teamId: String) {
        Messaging.messaging().subscribe(toTopic: "team_\(teamId)") { error in
            if let error = error {
                print("Error subscribing to team topic: \(error.localizedDescription)")
            } else {
                print("✅ Subscribed to team topic: team_\(teamId)")
            }
        }
    }
    
    /// Unsubscribes from team-specific notification topics
    func unsubscribeFromTeamNotifications(teamId: String) {
        Messaging.messaging().unsubscribe(fromTopic: "team_\(teamId)") { error in
            if let error = error {
                print("Error unsubscribing from team topic: \(error.localizedDescription)")
            } else {
                print("✅ Unsubscribed from team topic: team_\(teamId)")
            }
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            guard let token = fcmToken else { return }
            self.fcmToken = token
            print("🔄 FCM Token refreshed: \(token.prefix(20))...")
            
            // Upload new token if user is authenticated
            if let userId = Auth.auth().currentUser?.uid {
                await uploadFCMToken(token, userId: userId)
            }
        }
    }
}

#if os(iOS) || os(visionOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

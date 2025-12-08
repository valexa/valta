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
import FirebaseFirestore
import Observation

@Observable
@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    // MARK: - Properties
    
    var fcmToken: String?
    var isPermissionGranted: Bool = false
    var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    
    // Track the member ID we are currently registered as (in addition to Auth UID)
    private var registeredMemberID: String?
    
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
        print("📤 Uploading FCM token for user: \(userId)")
        
        do {
            try await FirestoreService.shared.saveFCMToken(token, for: userId)
            print("✅ FCM token uploaded for user: \(userId)")
        } catch {
            print("❌ Error uploading FCM token: \(error.localizedDescription)")
        }
    }
    
    /// Deletes FCM token from backend (on logout)
    func deleteFCMToken(userId: String) async {
        print("🗑️ Deleting FCM token for user: \(userId)")
        
        do {
            try await FirestoreService.shared.deleteFCMToken(for: userId)
            print("✅ FCM token deleted for user: \(userId)")
        } catch {
            print("❌ Error deleting FCM token: \(error.localizedDescription)")
        }
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
    
    /// Registers the current FCM token for a specific Team Member ID (UUID).
    /// This is crucial because Cloud Functions look up tokens by this UUID, not the Auth UID.
    func registerMemberID(_ id: UUID) async {
        let uuidString = id.uuidString
        await MainActor.run {
            self.registeredMemberID = uuidString
        }
        
        if let token = fcmToken {
            print("🔗 Linking FCM token to Member ID: \(uuidString)")
            await uploadFCMToken(token, userId: uuidString)
        }
    }
    
    /// Updates the member profile (name) in Firestore for notification lookup
    func updateMemberProfile(name: String) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            try await FirestoreService.shared.updateMemberName(name, for: userId)
            print("✅ Member profile updated with name: \(name)")
        } catch {
            print("❌ Error updating member profile: \(error.localizedDescription)")
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
            
            // Also upload for registered member ID if set
            if let memberId = self.registeredMemberID {
                await uploadFCMToken(token, userId: memberId)
            }
        }
    }
}

#if os(iOS) || os(visionOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Firestore Service (Internal Helper)

/// Helper class for Firestore operations (FCM Tokens only)
class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    // MARK: - FCM Tokens
    
    func saveFCMToken(_ token: String, for userId: String) async throws {
        let tokenData: [String: Any] = [
            "token": token,
            "updatedAt": FieldValue.serverTimestamp(),
            "appType": Bundle.main.bundleIdentifier?.contains("Manager") == true ? "valtaManager" : "valta"
        ]
        try await db.collection("fcmTokens").document(userId).setData(tokenData, merge: true)
    }
    
    func deleteFCMToken(for userId: String) async throws {
        try await db.collection("fcmTokens").document(userId).delete()
    }
    
    func getFCMToken(for userId: String) async throws -> String? {
        let snapshot = try await db.collection("fcmTokens").document(userId).getDocument()
        return snapshot.data()?["token"] as? String
    }
    
    func updateMemberName(_ name: String, for userId: String) async throws {
        try await db.collection("fcmTokens").document(userId).setData(["memberName": name], merge: true)
    }
}

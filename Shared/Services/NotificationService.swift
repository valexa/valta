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
    
    // Track the member email we are currently registered as (in addition to Auth UID)
    private var registeredMemberEmail: String?
    
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
    
    /// Retrieves the current FCM token (manual fetch)
    func retrieveFCMToken() async {
        do {
            let token = try await Messaging.messaging().token()
            await MainActor.run {
                self.fcmToken = token
            }
            
            // Upload token only if member email is registered
            if let memberEmail = self.registeredMemberEmail {
                await uploadFCMToken(token, userId: memberEmail)
            }
        } catch {
            print("❌ Error retrieving FCM token: \(error.localizedDescription)")
        }
    }

    /// Uploads FCM token to Firestore/backend
    private func uploadFCMToken(_ token: String, userId: String) async {
        do {
            try await FirestoreService.shared.saveFCMToken(token, for: userId)
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
    
    /// Registers the current FCM token for a specific Member Email.
    /// This is crucial because Cloud Functions look up tokens by email, not Auth UID.
    func registerMemberEmail(_ email: String) async {
        await MainActor.run {
            self.registeredMemberEmail = email
        }
        
        if let token = fcmToken {
            await uploadFCMToken(token, userId: email)
        }
    }
    
    /// Updates the member profile (name) in Firestore for notification lookup
    func updateMemberProfile(name: String) async {
        guard let memberEmail = self.registeredMemberEmail else { return }
        
        do {
            try await FirestoreService.shared.updateMemberName(name, for: memberEmail)
        } catch {
            print("❌ Error updating member profile: \(error.localizedDescription)")
        }
    }
    
    /// Fetches all member emails that have FCM tokens registered (indicating they are logged in elsewhere)
    func getLoggedInMemberEmails() async -> Set<String> {
        do {
            let emails = try await FirestoreService.shared.getAllFCMTokenEmails()
            return Set(emails)
        } catch {
            print("❌ Error fetching logged-in member emails: \(error.localizedDescription)")
            return []
        }
    }
}

// MARK: - MessagingDelegate

extension NotificationService: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            guard let token = fcmToken else { return }
            self.fcmToken = token
            
            // Only upload for registered member email (not Auth UID)
            if let memberEmail = self.registeredMemberEmail {
                await uploadFCMToken(token, userId: memberEmail)
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
    private let db: Firestore
    
    private init() {
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        let firestore = Firestore.firestore()
        firestore.settings = settings
        self.db = firestore
    }
    
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
    
    /// Returns all document IDs (member emails) from the fcmTokens collection
    func getAllFCMTokenEmails() async throws -> [String] {
        let snapshot = try await db.collection("fcmTokens").getDocuments()
        return snapshot.documents.map { $0.documentID }
    }
}

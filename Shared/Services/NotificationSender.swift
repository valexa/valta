//
//  NotificationSender.swift
//  Shared
//
//  Handles sending notifications via Firebase Cloud Functions.
//  Provides methods to send different types of activity notifications.
//
//  Created by vlad on 2025-12-05.
//

import Foundation
import FirebaseAuth
import FirebaseFunctions

// MARK: - Protocols

protocol CloudFunctionProvider {
    func call(name: String, data: [String: Any]) async throws -> Any
}

protocol AuthChecking {
    var isAuthenticated: Bool { get }
}

// MARK: - Default Implementations

struct FirebaseFunctionProvider: CloudFunctionProvider {
    private let functions = Functions.functions()

    func call(name: String, data: [String: Any]) async throws -> Any {
        let result = try await functions.httpsCallable(name).call(data)
        return result.data
    }
}

struct FirebaseAuthChecker: AuthChecking {
    var isAuthenticated: Bool {
        Auth.auth().currentUser != nil
    }
}

final class NotificationSender {
    static let shared = NotificationSender()

    private let functionProvider: CloudFunctionProvider
    private let authChecker: AuthChecking

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(
        functionProvider: CloudFunctionProvider = FirebaseFunctionProvider(),
        authChecker: AuthChecking = FirebaseAuthChecker()
    ) {
        self.functionProvider = functionProvider
        self.authChecker = authChecker
    }

    // MARK: - Helper

    /// Returns "P0 - " prefix for P0 activities, empty string otherwise
    private func priorityPrefix(for activity: Activity) -> String {
        return activity.priority == .p0 ? "P0 - " : ""
    }

    // MARK: - Notification Types

    /// 1. Sends notification when manager assigns activity to team member
    /// Recipient: Assigned team member
    func sendActivityAssignedNotification(
        activity: Activity,
        assignedTo member: TeamMember,
        managerName: String
    ) async throws {
        let createdDate = dateFormatter.string(from: activity.createdAt)
        let deadlineDate = dateFormatter.string(from: activity.deadline)
        let prefix = priorityPrefix(for: activity)

        // Format: [P0 - ][date] - [Manager] has assigned activity with deadline [date] to you, please start the activity: [Name].
        let message = "\(prefix)\(createdDate) - \(managerName) has assigned activity with deadline \(deadlineDate) to you, please start the activity: \(activity.name)."

        let data: [String: Any] = [
            "type": "activity_assigned",
            "activityId": activity.id.uuidString,
            "assignedMemberEmail": member.email,
            "assignedMemberName": member.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]

        print("📤 Sending notification for member: \(member.name)")
        print("   Member Email: \(member.email)")

        try await callCloudFunction(name: "sendActivityAssignedNotification", data: data)
    }

    /// 2. Sends notification when team member starts activity
    /// Recipient: Manager
    func sendActivityStartedNotification(
        activity: Activity,
        managerEmail: String?
    ) async throws {
        guard let managerEmail = managerEmail else {
            print("⚠️ No manager email available, skipping activity started notification")
            return
        }

        let startedDate = activity.startedAt.map { dateFormatter.string(from: $0) } ?? dateFormatter.string(from: Date())
        let deadlineDate = dateFormatter.string(from: activity.deadline)
        let prefix = priorityPrefix(for: activity)

        // Format: [P0 - ][date] - [Member] has started activity with deadline [date] for [Name].
        let message = "\(prefix)\(startedDate) - \(activity.assignedMember.name) has started activity with deadline \(deadlineDate) for \(activity.name)."

        let data: [String: Any] = [
            "type": "activity_started",
            "activityId": activity.id.uuidString,
            "managerEmail": managerEmail,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]

        try await callCloudFunction(name: "sendActivityStartedNotification", data: data)
    }

    /// 3. Sends notification when team member completes activity (requests approval)
    /// Recipient: Manager
    func sendCompletionRequestedNotification(
        activity: Activity
    ) async throws {
        let completedDate = activity.completedAt.map { dateFormatter.string(from: $0) } ?? dateFormatter.string(from: Date())
        let deadlineDate = dateFormatter.string(from: activity.deadline)
        let prefix = priorityPrefix(for: activity)

        // Format: [P0 - ][date] - [Member] has completed activity with deadline [date] for [Name].
        let message = "\(prefix)\(completedDate) - \(activity.assignedMember.name) has completed activity with deadline \(deadlineDate) for \(activity.name)."

        var data: [String: Any] = [
            "type": "completion_requested",
            "activityId": activity.id.uuidString,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]

        if let managerEmail = activity.managerEmail {
            data["managerEmail"] = managerEmail
        }

        try await callCloudFunction(name: "sendCompletionRequestedNotification", data: data)
    }

    /// 4. Sends notification when manager approves activity completion
    /// Recipient: Assigned team member
    func sendActivityApprovedNotification(
        activity: Activity,
        managerName: String,
        recipientEmail: String?
    ) async throws {
        guard let recipientEmail = recipientEmail else {
            print("⚠️ No recipient email available, skipping activity approved notification")
            return
        }

        let approvedDate = dateFormatter.string(from: Date())
        let prefix = priorityPrefix(for: activity)

        // Format: [P0 - ][date] - [Manager] has approved activity: [Name].
        let message = "\(prefix)\(approvedDate) - \(managerName) has approved activity: \(activity.name)."

        let data: [String: Any] = [
            "type": "activity_approved",
            "activityId": activity.id.uuidString,
            "recipientEmail": recipientEmail,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]

        try await callCloudFunction(name: "sendActivityApprovedNotification", data: data)
    }

    /// 5. Sends notification when manager rejects activity completion
    /// Recipient: Assigned team member
    func sendActivityRejectedNotification(
        activity: Activity,
        managerName: String,
        recipientEmail: String?
    ) async throws {
        guard let recipientEmail = recipientEmail else {
            print("⚠️ No recipient email available, skipping activity rejected notification")
            return
        }

        let rejectedDate = dateFormatter.string(from: Date())
        let prefix = priorityPrefix(for: activity)

        // Format: [P0 - ][date] - [Manager] has sent back your activity: [Name].
        let message = "\(prefix)\(rejectedDate) - \(managerName) has sent back your activity: \(activity.name)."

        let data: [String: Any] = [
            "type": "activity_rejected",
            "activityId": activity.id.uuidString,
            "recipientEmail": recipientEmail,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]

        try await callCloudFunction(name: "sendActivityRejectedNotification", data: data)
    }

    // MARK: - Cloud Function Call

    private func callCloudFunction(name: String, data: [String: Any]) async throws {
        guard authChecker.isAuthenticated else {
            throw NotificationError.notAuthenticated
        }

        do {
            let result = try await functionProvider.call(name: name, data: data)
            print("✅ Successfully called \(name): \(result)")
        } catch {
            print("❌ Error calling \(name): \(error.localizedDescription)")
            throw NotificationError.cloudFunctionError(error.localizedDescription)
        }
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError, Equatable {
    case notAuthenticated
    case cloudFunctionError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .cloudFunctionError(let message):
            return "Cloud Function error: \(message)"
        }
    }
}

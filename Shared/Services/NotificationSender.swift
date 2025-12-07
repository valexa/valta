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

@MainActor
final class NotificationSender {
    static let shared = NotificationSender()
    
    private let functions = Functions.functions()
    
    private init() {}
    
    // MARK: - Notification Types
    
    /// Sends notification when manager assigns activity to team member
    func sendActivityAssignedNotification(
        activity: Activity,
        assignedTo member: TeamMember,
        managerName: String
    ) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let createdDate = dateFormatter.string(from: activity.createdAt)
        let deadlineDate = dateFormatter.string(from: activity.deadline)
        
        let message = "\(managerName) has assigned \(activity.priority.shortName) activity on \(createdDate) with deadline \(deadlineDate) to you, please start the activity."
        
        let data: [String: Any] = [
            "type": "activity_assigned",
            "activityId": activity.id.uuidString,
            "assignedMemberId": member.id.uuidString,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]
        
        try await callCloudFunction(name: "sendActivityAssignedNotification", data: data)
    }
    
    /// Sends notification when team member starts activity (to all team members)
    func sendActivityStartedNotification(
        activity: Activity,
        team: Team
    ) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let startedDate = activity.startedAt.map { dateFormatter.string(from: $0) } ?? "now"
        let deadlineDate = dateFormatter.string(from: activity.deadline)
        
        let message = "\(activity.assignedMember.name)'s \(activity.priority.shortName) activity has started on \(startedDate) with deadline \(deadlineDate)."
        
        let data: [String: Any] = [
            "type": "activity_started",
            "activityId": activity.id.uuidString,
            "teamId": team.id.uuidString,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]
        
        try await callCloudFunction(name: "sendActivityStartedNotification", data: data)
    }
    
    /// Sends notification when team member requests completion approval (to manager)
    func sendCompletionRequestedNotification(
        activity: Activity
    ) async throws {
        let message = "\(activity.assignedMember.name) has requested completion approval for \(activity.priority.shortName) activity \"\(activity.name)\""
        
        let data: [String: Any] = [
            "type": "completion_requested",
            "activityId": activity.id.uuidString,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "message": message,
            "activityName": activity.name
        ]
        
        try await callCloudFunction(name: "sendCompletionRequestedNotification", data: data)
    }
    
    /// Sends notification when manager completes/approves activity (to all team members)
    func sendActivityCompletedNotification(
        activity: Activity,
        team: Team
    ) async throws {
        guard let outcome = activity.outcome else {
            throw NotificationError.missingOutcome
        }
        
        let outcomeText = outcome.rawValue.lowercased()
        let statusColor: String
        switch outcome {
        case .ahead:
            statusColor = "green"
        case .jit:
            statusColor = "amber"
        case .overrun:
            statusColor = "red"
        }
        
        let message = "\(activity.assignedMember.name)'s \(activity.priority.shortName) activity has completed \(outcomeText) with status \(statusColor)"
        
        let data: [String: Any] = [
            "type": "activity_completed",
            "activityId": activity.id.uuidString,
            "teamId": team.id.uuidString,
            "memberName": activity.assignedMember.name,
            "priority": activity.priority.shortName,
            "outcome": outcome.rawValue,
            "statusColor": statusColor,
            "message": message,
            "activityName": activity.name
        ]
        
        try await callCloudFunction(name: "sendActivityCompletedNotification", data: data)
    }
    
    // MARK: - Cloud Function Call
    
    private func callCloudFunction(name: String, data: [String: Any]) async throws {
        guard Auth.auth().currentUser != nil else {
            throw NotificationError.notAuthenticated
        }
        
        let function = functions.httpsCallable(name)
        
        do {
            let result = try await function.call(data)
            print("✅ Successfully called \(name): \(result.data ?? "no data")")
        } catch {
            print("❌ Error calling \(name): \(error.localizedDescription)")
            throw NotificationError.cloudFunctionError(error.localizedDescription)
        }
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case notAuthenticated
    case missingOutcome
    case cloudFunctionError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .missingOutcome:
            return "Activity outcome is required for completion notification"
        case .cloudFunctionError(let message):
            return "Cloud Function error: \(message)"
        }
    }
}

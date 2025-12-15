//
//  ActivityLogService.swift
//  Shared
//
//  Service for generating activity log entries from activities.
//  Follows Single Responsibility Principle.
//
//  Created by vlad on 2025-12-05.
//

import Foundation

class ActivityLogService {
    static let shared = ActivityLogService()

    private init() {}

    /// Generate log entries from activities based on their state
    func generateLogEntries(from activities: [Activity]) -> [ActivityLogEntry] {
        var entries: [ActivityLogEntry] = []

        for activity in activities {
            // Create log entry for creation
            entries.append(ActivityLogEntry(
                activity: activity,
                action: .created,
                timestamp: activity.createdAt,
                performedBy: activity.managerEmail ?? "Manager"
            ))

            // Create log entry for started (if started)
            if let startedAt = activity.startedAt {
                entries.append(ActivityLogEntry(
                    activity: activity,
                    action: .started,
                    timestamp: startedAt,
                    performedBy: activity.assignedMember.name
                ))
            }

            // Create log entry for completion request (if pending manager approval)
            if activity.status == .managerPending {
                // Use startedAt or createdAt as a proxy for when the request was made
                let requestTimestamp = activity.startedAt ?? activity.createdAt
                entries.append(ActivityLogEntry(
                    activity: activity,
                    action: .completionRequested,
                    timestamp: requestTimestamp,
                    performedBy: activity.assignedMember.name
                ))
            }

            // Create log entry for completed (if completed)
            if activity.status == .completed, let completedAt = activity.completedAt {
                entries.append(ActivityLogEntry(
                    activity: activity,
                    action: .completed,
                    timestamp: completedAt,
                    performedBy: activity.assignedMember.name
                ))
            }

            // Create log entry for canceled (if canceled)
            if activity.status == .canceled {
                // Use completedAt or createdAt as a proxy for when it was canceled
                let cancelTimestamp = activity.completedAt ?? activity.createdAt
                entries.append(ActivityLogEntry(
                    activity: activity,
                    action: .canceled,
                    timestamp: cancelTimestamp,
                    performedBy: activity.managerEmail ?? "Manager"
                ))
            }
        }

        // Sort by timestamp, most recent first
        return entries.sorted { $0.timestamp > $1.timestamp }
    }
}

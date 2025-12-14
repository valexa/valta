//
//  LiveActivityManager.swift
//  valta
//
//  Manages Live Activities for activity countdown timers on iOS.
//  This file is in the main app target to avoid naming conflicts with ActivityKit.Activity.
//
//  Created by vlad on 2025-12-14.
//

#if os(iOS)
import ActivityKit
import SwiftUI

// Make sure LiveActivityAttributes is available.
// It should be defined in valtaWidgets/LiveActivity.swift and included in the target.

/// Typealias using fully-qualified ActivityKit.Activity to avoid conflict with app's Activity model
typealias LiveActivityInstance = ActivityKit.Activity<LiveActivityAttributes>

@MainActor
class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var currentActivities: [UUID: LiveActivityInstance] = [:]

    private init() {
        // Restore existing activities from system
        restoreExistingActivities()
    }
    
    /// Restores any existing live activities that may be running from a previous session
    private func restoreExistingActivities() {
        for activity in LiveActivityInstance.activities {
            // Try to map back to UUID from attributes
            if let uuid = UUID(uuidString: activity.attributes.activityIdString) {
                currentActivities[uuid] = activity
                print("♻️ Restored existing Live Activity for: \(activity.attributes.activityName)")
            } else {
                // If we can't map it, we should probably end it as it's orphaned/invalid
                Task {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
    
    /// Syncs live activities with the current running activities
    /// - Parameters:
    ///   - runningActivities: List of activities that SHOULD be running (id, deadline, name, priority)
    ///   - memberName: Current member name
    func sync(runningActivityIds: Set<UUID>,
              activitiesInfo: [UUID: (name: String, deadline: Date, priority: String, colorHex: String)],
              memberName: String) async {
        
        // 1. End any live activities that are NOT in the running list
        for (id, _) in currentActivities {
            if !runningActivityIds.contains(id) {
                await endLiveActivity(for: id)
            }
        }
        
        // 2. Start or update live activities for running activities
        for id in runningActivityIds {
            guard let info = activitiesInfo[id] else { continue }
            
            if let existingLiveActivity = currentActivities[id] {
                // Update existing
                let timeRemaining = Int(info.deadline.timeIntervalSinceNow)
                let isOverdue = timeRemaining < 0
                await updateLiveActivity(for: id, timeRemaining: timeRemaining, isOverdue: isOverdue)
            } else {
                // Start new
                await startLiveActivity(
                    id: id,
                    name: info.name,
                    deadline: info.deadline,
                    priority: info.priority,
                    colorHex: info.colorHex,
                    memberName: memberName
                )
            }
        }
    }

    /// Starts a Live Activity for a running activity
    func startLiveActivity(id: UUID, name: String, deadline: Date, priority: String, colorHex: String, memberName: String) async {
        // Prevent duplicate activities
        if currentActivities[id] != nil {
            print("⚠️ Live Activity already exists for: \(name)")
            return
        }
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }

        let attributes = LiveActivityAttributes(
            activityName: name,
            priority: priority,
            priorityColorHex: colorHex,
            memberName: memberName,
            deadlineTimestamp: deadline.timeIntervalSince1970,
            activityIdString: id.uuidString
        )

        let timeRemaining = Int(deadline.timeIntervalSinceNow)
        let initialState = LiveActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            isOverdue: timeRemaining < 0,
            statusText: "Running"
        )

        do {
            let liveActivity = try LiveActivityInstance.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil // No push updates, we update locally
            )
            currentActivities[id] = liveActivity
            print("✅ Started Live Activity for: \(name)")
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    /// Updates the Live Activity with current state
    func updateLiveActivity(for activityId: UUID, timeRemaining: Int, isOverdue: Bool) async {
        guard let liveActivity = currentActivities[activityId] else { return }

        let newState = LiveActivityAttributes.ContentState(
            timeRemaining: timeRemaining,
            isOverdue: isOverdue,
            statusText: isOverdue ? "Overdue!" : "Running"
        )

        await liveActivity.update(.init(state: newState, staleDate: nil))
    }

    /// Ends a Live Activity when activity is completed or cancelled
    func endLiveActivity(for activityId: UUID, completed: Bool = true) async {
        guard let liveActivity = currentActivities[activityId] else { return }

        let finalState = LiveActivityAttributes.ContentState(
            timeRemaining: 0,
            isOverdue: false,
            statusText: completed ? "Completed" : "Cancelled"
        )

        await liveActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        currentActivities.removeValue(forKey: activityId)
        print("✅ Ended Live Activity for activity: \(activityId)")
    }
}
#endif

//
//  Activity+Extension.swift
//  valta
//
//  Created by vlad on 10/12/2025.
//

import Foundation
import SwiftUI

extension Activity {

    /// Returns the display color based on status, priority, outcome, and special rules
    var displayColor: Color {
        // For pending statuses, always use the status color (not outcome color)
        if status == .managerPending {
            return AppColors.statusManagerPending
        }
        if status == .teamMemberPending {
            return AppColors.statusTeamMemberPending
        }

        // Exception: For p0 activities if outcome is jit (on-time), color is red
        if priority == .p0, let outcome = outcome, outcome == .jit {
            return AppColors.destructive
        }

        // For completed activities, show outcome color
        if let outcome = outcome {
            return outcome.color
        }

        return status.color
    }

    /// Calculates the outcome based on completion time vs deadline
    /// - Parameter completionDate: The date of completion (defaults to now)
    /// - Returns: The calculated outcome (Ahead, JIT, or Overrun)
    ///
    /// Outcomes:
    /// - Ahead: Completed ≥30 min before deadline
    /// - Just In Time: Completed within ±5 min of deadline (before or after)
    /// - Overrun: Completed >5 min after deadline
    func calculateOutcome(completionDate: Date = Date()) -> ActivityOutcome {
        let timeDifference = (completedAt ?? completionDate).timeIntervalSince(deadline)

        // Constants for outcome thresholds
        let aheadThreshold: TimeInterval = 30 * 60  // 30 minutes in seconds
        let jitWindow: TimeInterval = 5 * 60        // 5 minutes in seconds

        // Overrun: completed more than 5 minutes after deadline
        if timeDifference > jitWindow {
            return .overrun
        }

        // Just In Time: completed within ±5 minutes of deadline
        if abs(timeDifference) <= jitWindow {
            return .jit
        }

        // Ahead: completed at least 30 minutes before deadline
        // (timeDifference is negative when before deadline)
        if timeDifference <= -aheadThreshold {
            return .ahead
        }

        // Edge case: completed between 5-30 minutes before deadline
        // Classify as JIT since it's not explicitly Ahead (≥30 min) and not within ±5 min
        // This ensures all cases are covered
        return .jit
    }

    // MARK: - Backend Updates

    /// Updates this activity in the backend (DataManager)
    /// - Parameter mutation: Closure to modify the activity
    @MainActor
    func updateInBackend(_ mutation: (inout Activity) -> Void) {
        let dataManager = DataManager.shared

        // Find the team containing this activity
        guard let teamIndex = dataManager.teams.findTeamIndex(containingActivityId: self.id) else {
            print("Error: Could not find team for activity \(self.name)")
            return
        }

        // Find the activity index
        guard let activityIndex = dataManager.teams[teamIndex].activities.findActivityIndex(byId: self.id) else {
            print("Error: Could not find activity \(self.name) in team")
            return
        }

        // Apply mutation
        mutation(&dataManager.teams[teamIndex].activities[activityIndex])

        // Notify observers immediately
        dataManager.notifyTeamsChanged()

        // Sync
        Task {
            await dataManager.syncActivities()
        }
    }

}

// MARK: - Activity Filtering Extensions

extension Array where Element == Activity {

    // MARK: - Status Filters

    var running: [Activity] {
        filter { $0.status == .running }
    }

    var completed: [Activity] {
        filter { $0.status == .completed }
    }

    var canceled: [Activity] {
        filter { $0.status == .canceled }
    }

    var managerPending: [Activity] {
        filter { $0.status == .managerPending }
    }

    var teamMemberPending: [Activity] {
        filter { $0.status == .teamMemberPending }
    }

    /// All pending activities (both manager and team member pending)
    var allPending: [Activity] {
        filter { $0.status == .managerPending || $0.status == .teamMemberPending }
    }

    /// Active activities (running or pending)
    var active: [Activity] {
        filter {
            $0.status == .running ||
            $0.status == .teamMemberPending ||
            $0.status == .managerPending
        }
    }

    // MARK: - Outcome Filters

    var completedAhead: [Activity] {
        completed.filter { $0.outcome == .ahead }
    }

    var completedJIT: [Activity] {
        completed.filter { $0.outcome == .jit }
    }

    var completedOverrun: [Activity] {
        completed.filter { $0.outcome == .overrun }
    }

    // MARK: - Priority Filters

    func byPriority(_ priority: ActivityPriority) -> [Activity] {
        filter { $0.priority == priority }
    }

    // MARK: - Member Filters

    func assignedTo(_ member: TeamMember) -> [Activity] {
        filter { $0.assignedMember.id == member.id }
    }

    func assignedTo(memberId: UUID) -> [Activity] {
        filter { $0.assignedMember.id == memberId }
    }

    // MARK: - Search

    func search(_ query: String) -> [Activity] {
        guard !query.isEmpty else { return self }
        return filter { activity in
            activity.name.localizedCaseInsensitiveContains(query) ||
            activity.description.localizedCaseInsensitiveContains(query) ||
            activity.assignedMember.name.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Sorting

    func sortedByDeadline(ascending: Bool = true) -> [Activity] {
        sorted {
            ascending ? $0.deadline < $1.deadline : $0.deadline > $1.deadline
        }
    }

    func sortedByPriority() -> [Activity] {
        sorted { $0.priority < $1.priority }
    }

    func sortedByCreatedAt(ascending: Bool = false) -> [Activity] {
        sorted {
            ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
        }
    }
}

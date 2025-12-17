//
//  ManagerAppState.swift
//  valtaManager
//
//  Observable state management for the Manager app.
//  Delegates to services for filtering, stats, and mutations.
//
//  Uses Observation framework for automatic UI updates.
//
//  Created by Vlad on 2025-12-08.
//

import SwiftUI
import Observation
import FirebaseAuth

@Observable
final class ManagerAppState: BaseAppState, ActivityDataProviding {

    // MARK: - UI State

    var showingNewActivitySheet: Bool = false
    var selectedActivity: Activity?

    // MARK: - Services

    private let teamService = TeamService()

    // MARK: - Initialization

    override init() {
        super.init()
    }

    override func onTeamsChanged() {
        super.onTeamsChanged()

        // Register manager email for notifications once data is loaded
        if let team = dataManager.teams.first, let managerEmail = team.managerEmail {
            Task {
                await NotificationService.shared.registerMemberEmail(managerEmail)
            }
        }
    }

    // MARK: - Data Accessors

    var team: Team {
        _ = dataVersion
        return dataManager.teams.first ?? Team(name: "Loading...", members: [])
    }

    // Protocol provides: activityFilter, activityStats

    var totalActivities: Int { totalActivitiesCount }
    var pendingCount: Int { allPendingCount }

    // MARK: - Activity Actions (delegate to service)

    func approveCompletion(_ activity: Activity) {
        var updatedActivity = activity

        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .completed
            // Calculate outcome based on existing completion time (if set) or now
            let completionTime = mutableActivity.completedAt ?? Date()
            mutableActivity.completedAt = completionTime
            mutableActivity.outcome = mutableActivity.calculateOutcome(completionDate: completionTime)

            // Capture updated state
            updatedActivity = mutableActivity
        }

        let finalActivity = updatedActivity
        let managerName = team.managerEmail ?? "Manager"
        Task {
            // Send approval notification to assigned team member
            do {
                try await NotificationSender.shared.sendActivityApprovedNotification(
                    activity: finalActivity,
                    managerName: managerName,
                    recipientEmail: finalActivity.assignedMember.email
                )
            } catch {
                print("⚠️ Failed to send activity approved notification: \(error.localizedDescription)")
            }
        }
    }

    func rejectCompletion(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .running
            mutableActivity.outcome = nil
        }

        let managerName = team.managerEmail ?? "Manager"
        Task {
            // Send rejection notification to assigned team member
            do {
                try await NotificationSender.shared.sendActivityRejectedNotification(
                    activity: activity,
                    managerName: managerName,
                    recipientEmail: activity.assignedMember.email
                )
            } catch {
                print("⚠️ Failed to send activity rejected notification: \(error.localizedDescription)")
            }
        }
    }

    func completeActivity(_ activity: Activity) {
        var updatedActivity = activity

        activity.updateInBackend { mutableActivity in
            let now = Date()
            mutableActivity.status = .completed
            mutableActivity.completedAt = now
            mutableActivity.outcome = mutableActivity.calculateOutcome(completionDate: now)

            // Capture updated state
            updatedActivity = mutableActivity
        }

        let finalActivity = updatedActivity
        let managerName = team.managerEmail ?? "Manager"
        Task {
            // Send approval notification to assigned team member
            do {
                try await NotificationSender.shared.sendActivityApprovedNotification(
                    activity: finalActivity,
                    managerName: managerName,
                    recipientEmail: finalActivity.assignedMember.email
                )
            } catch {
                print("⚠️ Failed to send activity approved notification: \(error.localizedDescription)")
            }
        }
    }

    func cancelActivity(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .canceled
        }
    }

    // MARK: - Team Actions (delegate to service)

    func addActivity(_ activity: Activity) {
        guard let teamIndex = dataManager.teams.findTeamIndex(byId: team.id) else { return }

        // Inject manager email from team data
        var newActivity = activity
        if let team = dataManager.teams.findTeam(byId: team.id) {
            newActivity.managerEmail = team.managerEmail
        }

        teamService.addActivity(newActivity, to: &dataManager.teams[teamIndex])

        Task {
            await dataManager.syncActivities()

            // Send notification to assigned team member
            do {
                // Use manager email from team data
                let managerName = newActivity.managerEmail ?? "Manager"
                try await NotificationSender.shared.sendActivityAssignedNotification(
                    activity: newActivity,
                    assignedTo: newActivity.assignedMember,
                    managerName: managerName
                )
            } catch {
                print("⚠️ Failed to send activity assigned notification: \(error.localizedDescription)")
            }
        }
    }
}

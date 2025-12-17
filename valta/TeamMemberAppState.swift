//
//  TeamMemberAppState.swift
//  valta
//
//  Observable state management for the Team Member app.
//  Delegates to services for filtering, stats, and mutations.
//
//  Uses Observation framework for automatic UI updates.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI
import Observation

@Observable
final class TeamMemberAppState: BaseAppState, ActivityDataProviding {

    // MARK: - Constants

    static let selectedMemberEmailKey = "com.valta.selectedMemberEmail"

    // MARK: - Services

    private let logService = ActivityLogService.shared

    // MARK: - Data State

    var currentMember: TeamMember?

    // Activity log - derived from activities via service
    var activityLog: [ActivityLogEntry] {
        logService.generateLogEntries(from: team.activities)
    }

    // MARK: - UI State

    var selectedTab: TeamMemberTab = .activities
    var showingCompletionSheet: Bool = false
    var selectedActivityForCompletion: Activity?

    // MARK: - Initialization

    override init() {
        super.init()
    }

    // Callbacks from DataManager
    override func onTeamsChanged() {
        super.onTeamsChanged()
        // Try to restore saved member if not yet onboarded
        if !hasCompletedOnboarding {
            restoreSavedMember()
        }
    }

    /// Restores the selected member from UserDefaults if available
    private func restoreSavedMember() {
        guard let savedEmail = UserDefaults.standard.string(forKey: Self.selectedMemberEmailKey) else { return }

        // Find member with this email across all teams
        for team in dataManager.teams {
            if let member = team.members.first(where: { $0.email == savedEmail }) {
                currentMember = member
                hasCompletedOnboarding = true

                // Re-register FCM token for this member
                Task {
                    await NotificationService.shared.registerMemberEmail(member.email)
                }
                return
            }
        }
    }

    // MARK: - Data Accessors (delegate to DataManager)

    var team: Team {
        _ = dataVersion // depend on version to trigger refresh
        // Find the team that contains the current member
        if let member = currentMember {
            return dataManager.teams.findTeam(containingMemberId: member.id) ?? Team(name: "Loading...", members: [])
        }
        return dataManager.teams.first ?? Team(name: "Loading...", members: [])
    }

    // MARK: - Filters (computed via services)

    /// Activity stats for current member's activities
    var myStats: ActivityStats {
        ActivityStats(activities: myActivities)
    }

    // MARK: - My Activities

    var myActivities: [Activity] {
        guard let member = currentMember else { return [] }
        return team.activities.assignedTo(member)
    }

    // MARK: - Stats (delegate to stats services)

    var myActiveCount: Int { myStats.active }
    var myAheadCount: Int { myStats.completedAhead }
    var myJITCount: Int { myStats.completedJIT }
    var myOverrunCount: Int { myStats.completedOverrun }

    var teamActiveCount: Int { activeCount }
    var teamRunningCount: Int { runningCount }
    var teamCompletedCount: Int { completedCount }
    var teamPendingCount: Int { allPendingCount }
    var teamAheadCount: Int { completedAheadCount }
    var teamJITCount: Int { completedJITCount }
    var teamOverrunCount: Int { completedOverrunCount }

    // MARK: - Actions (delegate to service)

    func startActivity(_ activity: Activity) {
        var updatedActivity = activity

        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .running
            mutableActivity.startedAt = Date()
            updatedActivity = mutableActivity
        }

        // Send notification to manager using updated state
        let finalActivity = updatedActivity
        Task {
            do {
                try await NotificationSender.shared.sendActivityStartedNotification(
                    activity: finalActivity,
                    managerEmail: finalActivity.managerEmail
                )
            } catch {
                print("⚠️ Failed to send activity started notification: \(error.localizedDescription)")
            }
        }
    }

    func requestReview(_ activity: Activity) {
        var updatedActivity = activity

        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .managerPending
            mutableActivity.outcome = nil
            mutableActivity.completedAt = Date()
            updatedActivity = mutableActivity
        }

        // Send notification to manager using updated state
        let finalActivity = updatedActivity
        Task {
            do {
                try await NotificationSender.shared.sendCompletionRequestedNotification(
                    activity: finalActivity
                )
                print("🔔 Notification sent to manager for activity: \(finalActivity.name)")
            } catch {
                print("⚠️ Failed to send completion requested notification: \(error.localizedDescription)")
            }
        }
    }

    func selectMember(_ member: TeamMember) {
        currentMember = member
        hasCompletedOnboarding = true

        // Persist member email to UserDefaults
        UserDefaults.standard.set(member.email, forKey: Self.selectedMemberEmailKey)

        // Update notification profile and link token
        Task {
            // CRITICAL: Link the FCM token to this member's email so Cloud Functions can find it
            await NotificationService.shared.registerMemberEmail(member.email)

            // Update the name for display purposes (optional but useful for debugging)
            await NotificationService.shared.updateMemberProfile(name: member.name)
        }
    }
}

// MARK: - Team Member Tab

enum TeamMemberTab: Hashable {
    case activities
    case team
    case log
}

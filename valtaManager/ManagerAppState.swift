//
//  ManagerAppState.swift
//  valtaManager
//
//  Observable state management for the Manager app.
//  Delegates to services for filtering, stats, and mutations.
//
//  Uses Observation framework for automatic UI updates.
//
//  Created by ANTIGRAVITY on 2025-12-08.
//

import SwiftUI
import Observation
import FirebaseAuth

@Observable
final class ManagerAppState {
    
    // MARK: - Services
    
    private let activityService = ActivityService()
    private let teamService = TeamService()
    
    // Reference to DataManager for live data
    private let dataManager = DataManager.shared
    
    // MARK: - Data State
    
    var hasCompletedOnboarding: Bool = false
    
    // MARK: - UI State
    
    var showingNewActivitySheet: Bool = false
    var selectedActivity: Activity? = nil
    var dataVersion: Int = 0
    
    // MARK: - Initialization

    init() {
        // Observe DataManager team changes
        NotificationCenter.default.addObserver(forName: DataManager.dataChangedNotification, object: nil, queue: .main) { [weak self] _ in
            self?.dataVersion &+= 1
            
            // Register manager email for notifications once data is loaded
            if let team = self?.dataManager.teams.first, let managerEmail = team.managerEmail {
                Task {
                    await NotificationService.shared.registerMemberEmail(managerEmail)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data Accessors (delegate to DataManager)
    
    var team: Team {
        _ = dataVersion
        return dataManager.teams.first ?? Team(name: "Loading...", members: [])
    }
    
    // MARK: - Filters & Stats (computed via services)
    
    /// Activity filter for querying
    var activityFilter: ActivityFilter {
        team.activityFilter
    }
    
    /// Activity statistics
    var activityStats: ActivityStats {
        team.activityStats
    }
    
    // MARK: - Convenience Accessors (delegate to filter)
    
    var activeActivities: [Activity] {
        activityFilter.active
    }
    
    var pendingActivities: [Activity] {
        activityFilter.managerPending
    }
    
    var completedActivities: [Activity] {
        activityFilter.completed
    }
    
    var canceledActivities: [Activity] {
        activityFilter.canceled
    }
    
    // MARK: - Stats (delegate to activityStats)
    
    var totalActivities: Int { activityStats.total }
    var runningCount: Int { activityStats.running }
    var pendingCount: Int { activityStats.allPending }
    var completedCount: Int { activityStats.completed }
    
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
        Task {
            // Send notification to all team members
            do {
                try await NotificationSender.shared.sendActivityCompletedNotification(
                    activity: finalActivity,
                    team: team
                )
            } catch {
                print("⚠️ Failed to send activity completed notification: \(error.localizedDescription)")
            }
        }
    }
    
    func rejectCompletion(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .running
            mutableActivity.outcome = nil
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
        Task {
            // Send notification to all team members
            do {
                try await NotificationSender.shared.sendActivityCompletedNotification(
                    activity: finalActivity,
                    team: team
                )
            } catch {
                print("⚠️ Failed to send activity completed notification: \(error.localizedDescription)")
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

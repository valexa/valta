//
//  AppState.swift
//  valtaManager
//
//  Observable state management for the Manager app.
//  Delegates to services for filtering, stats, and mutations.
//
//  Uses Observation framework for automatic UI updates.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI
import Observation

@Observable
final class AppState {
    
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
        // Observe DataManager team changes via callback
        DataManager.shared.onTeamsChanged = { [weak self] in
            self?.dataVersion &+= 1
        }
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
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .completed
            // Calculate outcome based on existing completion time (if set) or now
            let completionTime = mutableActivity.completedAt ?? Date()
            mutableActivity.completedAt = completionTime
            mutableActivity.outcome = mutableActivity.calculateOutcome(completionDate: completionTime)
        }
        dataManager.notifyTeamsChanged()
        Task {
            await dataManager.syncActivities()
        }
        dataVersion &+= 1
    }
    
    func rejectCompletion(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .running
            mutableActivity.outcome = nil
        }
        dataManager.notifyTeamsChanged()
        dataVersion &+= 1
    }
    
    func completeActivity(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            let now = Date()
            mutableActivity.status = .completed
            mutableActivity.completedAt = now
            mutableActivity.outcome = mutableActivity.calculateOutcome(completionDate: now)
        }
        dataManager.notifyTeamsChanged()
        Task {
            await dataManager.syncActivities()
        }
        dataVersion &+= 1
    }
    
    func cancelActivity(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .canceled
        }
    }
    
    // MARK: - Team Actions (delegate to service)
    
    func addActivity(_ activity: Activity) {
        guard let teamIndex = dataManager.teams.firstIndex(where: { $0.id == team.id }) else { return }
        
        teamService.addActivity(activity, to: &dataManager.teams[teamIndex])
        
        Task {
            await dataManager.syncActivities()
        }
    }
}


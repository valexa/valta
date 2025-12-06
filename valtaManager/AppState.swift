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
    private let completionRequestService = CompletionRequestService()
    
    /// Timer for refreshing time-based displays
    let refreshTimer = RefreshTimer.shared
    
    // Reference to DataManager for live data
    private let dataManager = DataManager.shared
    
    // MARK: - Data State
    
    var hasCompletedOnboarding: Bool = false
    
    // Completion requests are derived from activities with managerPending status
    var completionRequests: [CompletionRequest] {
        dataManager.teams.flatMap { $0.activities }
            .filter { $0.status == .managerPending }
            .map { activity in
                CompletionRequest(
                    activity: activity,
                    requestedAt: activity.startedAt ?? Date(),
                    requestedOutcome: activity.outcome ?? .jit
                )
            }
    }
    
    // MARK: - UI State
    
    var showingNewActivitySheet: Bool = false
    var selectedActivity: Activity? = nil
    
    // MARK: - Initialization
    
    init() {
        refreshTimer.start()
    }
    
    // MARK: - Time Refresh
    
    /// Current refresh tick - observe this to trigger time-based UI updates
    var refreshTick: UInt64 {
        refreshTimer.tick
    }
    
    // MARK: - Data Accessors (delegate to DataManager)
    
    var team: Team {
        // Return the first team from DataManager, or a placeholder if empty
        dataManager.teams.first ?? Team(name: "Loading...", members: [])
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
    
    func approveCompletion(_ request: CompletionRequest) {
        // Update local team activities
        guard let teamIndex = dataManager.teams.firstIndex(where: { $0.id == team.id }) else { return }
        
        // Find and complete the activity
        if let activityIndex = dataManager.teams[teamIndex].activities.firstIndex(where: { $0.id == request.activity.id }) {
            dataManager.teams[teamIndex].activities[activityIndex].status = .completed
            dataManager.teams[teamIndex].activities[activityIndex].completedAt = Date()
        }
        
        // Sync to Firebase
        Task {
            await dataManager.syncActivities()
        }
    }
    
    func rejectCompletion(_ request: CompletionRequest) {
        guard let teamIndex = dataManager.teams.firstIndex(where: { $0.id == team.id }) else { return }
        
        // Find and revert the activity to running
        if let activityIndex = dataManager.teams[teamIndex].activities.firstIndex(where: { $0.id == request.activity.id }) {
            dataManager.teams[teamIndex].activities[activityIndex].status = .running
        }
        
        Task {
            await dataManager.syncActivities()
        }
    }
    
    func completeActivity(_ activity: Activity, outcome: ActivityOutcome) {
        guard let teamIndex = dataManager.teams.firstIndex(where: { $0.id == team.id }) else { return }
        
        activityService.completeActivity(
            id: activity.id,
            outcome: outcome,
            in: &dataManager.teams[teamIndex].activities
        )
        
        Task {
            await dataManager.syncActivities()
        }
    }
    
    func cancelActivity(_ activity: Activity) {
        guard let teamIndex = dataManager.teams.firstIndex(where: { $0.id == team.id }) else { return }
        
        activityService.cancelActivity(id: activity.id, in: &dataManager.teams[teamIndex].activities)
        
        Task {
            await dataManager.syncActivities()
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

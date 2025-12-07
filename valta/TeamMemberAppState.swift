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
final class TeamMemberAppState {
    
    // MARK: - Services
    
    private let activityService = ActivityService()
    private let logService = ActivityLogService.shared
    
    // Reference to DataManager for live data
    private let dataManager = DataManager.shared
    
    // MARK: - Data State
    
    var hasCompletedOnboarding: Bool = false
    var currentMember: TeamMember? = nil
    
    // Activity log - derived from activities via service
    var activityLog: [ActivityLogEntry] {
        logService.generateLogEntries(from: team.activities)
    }
    
    // MARK: - UI State
    
    var selectedTab: TeamMemberTab = .activities
    var showingCompletionSheet: Bool = false
    var selectedActivityForCompletion: Activity? = nil
    var dataVersion: Int = 0
    
    // MARK: - Initialization
    
    init() {
        // Observe DataManager team changes via callback
        DataManager.shared.onTeamsChanged = { [weak self] in
            self?.onTeamsChanged()
        }
    }
    
    // Callbacks from DataManager
    func onTeamsChanged() {
        dataVersion &+= 1
    }
    
    // MARK: - Data Accessors (delegate to DataManager)
    
    var team: Team {
        _ = dataVersion // depend on version to trigger refresh
        // Find the team that contains the current member
        if let member = currentMember {
            return dataManager.teams.first(where: { team in
                team.members.contains(where: { $0.id == member.id })
            }) ?? Team(name: "Loading...", members: [])
        }
        return dataManager.teams.first ?? Team(name: "Loading...", members: [])
    }
    
    // MARK: - Filters (computed via services)
    
    /// Activity filter for all team activities
    var teamFilter: ActivityFilter {
        team.activityFilter
    }
    
    /// Activity filter for current member's activities
    var myFilter: ActivityFilter {
        guard let member = currentMember else {
            return ActivityFilter(activities: [])
        }
        return teamFilter.assignedTo(member)
    }
    
    /// Activity stats for all team activities
    var teamStats: ActivityStats {
        ActivityStats(filter: teamFilter)
    }
    
    /// Activity stats for current member's activities
    var myStats: ActivityStats {
        ActivityStats(filter: myFilter)
    }
    
    // MARK: - My Activities (delegate to filter)
    
    var myActivities: [Activity] {
        myFilter.activities
    }
    
    var myPendingActivities: [Activity] {
        myFilter.teamMemberPending
    }
    
    var myRunningActivities: [Activity] {
        myFilter.running
    }
    
    var myAwaitingApproval: [Activity] {
        myFilter.managerPending
    }
    
    var myCompletedActivities: [Activity] {
        myFilter.completed
    }
    
    var myCompletedAhead: [Activity] {
        myFilter.completedAhead
    }
    
    var myCompletedJIT: [Activity] {
        myFilter.completedJIT
    }
    
    var myCompletedOverrun: [Activity] {
        myFilter.completedOverrun
    }
    
    // MARK: - Team Activities (delegate to filter)
    
    var teamActiveActivities: [Activity] {
        teamFilter.active
    }
    
    var teamCompletedActivities: [Activity] {
        teamFilter.completed
    }
    
    var teamRunningActivities: [Activity] {
        teamFilter.running
    }
    
    var teamPendingActivities: [Activity] {
        teamFilter.allPending
    }
    
    var teamCompletedAhead: [Activity] {
        teamFilter.completedAhead
    }
    
    var teamCompletedJIT: [Activity] {
        teamFilter.completedJIT
    }
    
    var teamCompletedOverrun: [Activity] {
        teamFilter.completedOverrun
    }
    
    // MARK: - Stats (delegate to stats services)
    
    var myActiveCount: Int { myStats.active }
    var myAheadCount: Int { myStats.completedAhead }
    var myJITCount: Int { myStats.completedJIT }
    var myOverrunCount: Int { myStats.completedOverrun }
    
    var teamActiveCount: Int { teamStats.active }
    var teamRunningCount: Int { teamStats.running }
    var teamCompletedCount: Int { teamStats.completed }
    var teamPendingCount: Int { teamStats.allPending }
    var teamAheadCount: Int { teamStats.completedAhead }
    var teamJITCount: Int { teamStats.completedJIT }
    var teamOverrunCount: Int { teamStats.completedOverrun }
    var pendingApprovalCount: Int { myStats.managerPending }
    
    // MARK: - Actions (delegate to service)
    
    func startActivity(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .running
            mutableActivity.startedAt = Date()
        }
    }
    
    func requestReview(_ activity: Activity) {
        activity.updateInBackend { mutableActivity in
            mutableActivity.status = .managerPending
            mutableActivity.outcome = nil
            mutableActivity.completedAt = Date()
        }
        
        print("🔔 Notification sent to manager for activity: \(activity.name)")
    }
    
    func selectMember(_ member: TeamMember) {
        currentMember = member
        hasCompletedOnboarding = true
    }
}

// MARK: - Team Member Tab

enum TeamMemberTab: Hashable {
    case activities
    case team
    case log
}

//
//  ActivityService.swift
//  Shared
//
//  Provides business logic and mutation operations for activities.
//  Follows Single Responsibility Principle - handles only activity mutations.
//
//  Created by vlad on 2025-12-04.
//

import Foundation

// MARK: - Activity Service Protocol

/// Protocol defining activity mutation operations
protocol ActivityServiceProtocol {
    func startActivity(id: UUID, in activities: inout [Activity]) -> Activity?
    func completeActivity(id: UUID, outcome: ActivityOutcome, in activities: inout [Activity]) -> Activity?
    func cancelActivity(id: UUID, in activities: inout [Activity]) -> Activity?
    func requestCompletion(id: UUID, outcome: ActivityOutcome, in activities: inout [Activity]) -> Activity?
    func approveCompletion(id: UUID, in activities: inout [Activity]) -> Activity?
    func rejectCompletion(id: UUID, in activities: inout [Activity]) -> Activity?
}

// MARK: - Activity Service

/// Handles all activity mutation operations
struct ActivityService: ActivityServiceProtocol {

    /// Current date provider for testability
    var now: () -> Date = { Date() }

    // MARK: - Start Activity

    /// Starts an activity (changes status from teamMemberPending to running)
    @discardableResult
    func startActivity(id: UUID, in activities: inout [Activity]) -> Activity? {
        guard let idx = activities.findActivityIndex(byId: id) else { return nil }
        guard activities[idx].status == .teamMemberPending else { return nil }

        activities[idx].status = .running
        activities[idx].startedAt = now()

        return activities[idx]
    }

    // MARK: - Complete Activity

    /// Completes an activity directly (manager action)
    @discardableResult
    func completeActivity(id: UUID, outcome: ActivityOutcome, in activities: inout [Activity]) -> Activity? {
        guard let idx = activities.findActivityIndex(byId: id) else { return nil }

        activities[idx].status = .completed
        activities[idx].outcome = outcome
        activities[idx].completedAt = now()

        return activities[idx]
    }

    // MARK: - Cancel Activity

    /// Cancels an activity
    @discardableResult
    func cancelActivity(id: UUID, in activities: inout [Activity]) -> Activity? {
        guard let idx = activities.findActivityIndex(byId: id) else { return nil }
        guard activities[idx].status != .completed else { return nil }

        activities[idx].status = .canceled

        return activities[idx]
    }

    // MARK: - Request Completion

    /// Requests completion approval (team member action)
    @discardableResult
    func requestCompletion(id: UUID, outcome: ActivityOutcome, in activities: inout [Activity]) -> Activity? {
        guard let idx = activities.findActivityIndex(byId: id) else { return nil }
        guard activities[idx].status == .running else { return nil }

        activities[idx].status = .managerPending
        activities[idx].outcome = outcome

        return activities[idx]
    }

    // MARK: - Approve Completion

    /// Approves a completion request (manager action)
    @discardableResult
    func approveCompletion(id: UUID, in activities: inout [Activity]) -> Activity? {
        guard let idx = activities.findActivityIndex(byId: id) else { return nil }
        guard activities[idx].status == .managerPending else { return nil }

        activities[idx].status = .completed
        activities[idx].completedAt = now()

        return activities[idx]
    }

    // MARK: - Reject Completion

    /// Rejects a completion request, returning activity to running state
    @discardableResult
    func rejectCompletion(id: UUID, in activities: inout [Activity]) -> Activity? {
        guard let idx = activities.findActivityIndex(byId: id) else { return nil }
        guard activities[idx].status == .managerPending else { return nil }

        activities[idx].status = .running
        activities[idx].outcome = nil

        return activities[idx]
    }
}

// MARK: - Team Service

/// Handles team member operations
struct TeamService {

    /// Adds a member to the team
    func addMember(_ member: TeamMember, to team: inout Team) {
        team.members.append(member)
    }

    /// Removes a member from the team
    func removeMember(id: UUID, from team: inout Team) {
        team.members.removeAll { $0.id == id }
    }

    /// Adds an activity to the team
    func addActivity(_ activity: Activity, to team: inout Team) {
        team.activities.insert(activity, at: 0)
    }

    /// Removes an activity from the team
    func removeActivity(id: UUID, from team: inout Team) {
        team.activities.removeAll { $0.id == id }
    }
}

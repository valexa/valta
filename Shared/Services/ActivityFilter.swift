//
//  ActivityFilter.swift
//  Shared
//
//  Provides filtering and querying capabilities for activities.
//  Follows Single Responsibility Principle - handles only activity filtering.
//
//  Created by vlad on 2025-12-04.
//

import Foundation

// MARK: - Activity Filter

/// Provides filtering and querying capabilities for a collection of activities
struct ActivityFilter {

    let activities: [Activity]

    // MARK: - Status Filters

    var running: [Activity] {
        activities.filter { $0.status == .running }
    }

    var completed: [Activity] {
        activities.filter { $0.status == .completed }
    }

    var canceled: [Activity] {
        activities.filter { $0.status == .canceled }
    }

    var managerPending: [Activity] {
        activities.filter { $0.status == .managerPending }
    }

    var teamMemberPending: [Activity] {
        activities.filter { $0.status == .teamMemberPending }
    }

    /// All pending activities (both manager and team member pending)
    var allPending: [Activity] {
        activities.filter { $0.status == .managerPending || $0.status == .teamMemberPending }
    }

    /// Active activities (running or pending)
    var active: [Activity] {
        activities.filter {
            $0.status == .running ||
            $0.status == .teamMemberPending ||
            $0.status == .managerPending
        }
    }

    // MARK: - Outcome Filters (for completed activities)

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
        activities.filter { $0.priority == priority }
    }

    var p0: [Activity] { byPriority(.p0) }
    var p1: [Activity] { byPriority(.p1) }
    var p2: [Activity] { byPriority(.p2) }
    var p3: [Activity] { byPriority(.p3) }

    // MARK: - Member Filters

    func assignedTo(_ member: TeamMember) -> ActivityFilter {
        ActivityFilter(activities: activities.filter { $0.assignedMember.id == member.id })
    }

    func assignedTo(memberId: UUID) -> ActivityFilter {
        ActivityFilter(activities: activities.filter { $0.assignedMember.id == memberId })
    }

    // MARK: - Status Filter

    func byStatus(_ status: ActivityStatus) -> [Activity] {
        activities.filter { $0.status == status }
    }

    // MARK: - Outcome Filter

    func byOutcome(_ outcome: ActivityOutcome) -> [Activity] {
        activities.filter { $0.outcome == outcome }
    }

    // MARK: - Time-based Filters

    var overdue: [Activity] {
        activities.filter { $0.isOverdue }
    }

    func dueBefore(_ date: Date) -> [Activity] {
        activities.filter { $0.deadline < date }
    }

    func dueAfter(_ date: Date) -> [Activity] {
        activities.filter { $0.deadline > date }
    }

    func createdBetween(_ start: Date, _ end: Date) -> [Activity] {
        activities.filter { $0.createdAt >= start && $0.createdAt <= end }
    }

    // MARK: - Search

    func search(_ query: String) -> [Activity] {
        guard !query.isEmpty else { return activities }
        return activities.filter { activity in
            activity.name.localizedCaseInsensitiveContains(query) ||
            activity.description.localizedCaseInsensitiveContains(query) ||
            activity.assignedMember.name.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Sorting

    func sortedByDeadline(ascending: Bool = true) -> [Activity] {
        activities.sorted {
            ascending ? $0.deadline < $1.deadline : $0.deadline > $1.deadline
        }
    }

    func sortedByPriority() -> [Activity] {
        activities.sorted { $0.priority < $1.priority }
    }

    func sortedByCreatedAt(ascending: Bool = false) -> [Activity] {
        activities.sorted {
            ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
        }
    }
}

// MARK: - Team Extension

extension Team {
    /// Creates an ActivityFilter for all team activities
    var activityFilter: ActivityFilter {
        ActivityFilter(activities: activities)
    }
}

// MARK: - Array Extension

extension Array where Element == Activity {
    /// Creates an ActivityFilter for this array of activities
    var filter: ActivityFilter {
        ActivityFilter(activities: self)
    }
}

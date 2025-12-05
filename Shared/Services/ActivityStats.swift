//
//  ActivityStats.swift
//  Shared
//
//  Provides statistics calculations for activities.
//  Follows Single Responsibility Principle - handles only statistics.
//
//  Created by vlad on 2025-12-04.
//

import Foundation

// MARK: - Activity Stats

/// Calculates statistics for a collection of activities
struct ActivityStats {
    
    private let filter: ActivityFilter
    
    init(activities: [Activity]) {
        self.filter = ActivityFilter(activities: activities)
    }
    
    init(filter: ActivityFilter) {
        self.filter = filter
    }
    
    // MARK: - Count Stats
    
    var total: Int { filter.activities.count }
    var running: Int { filter.running.count }
    var completed: Int { filter.completed.count }
    var canceled: Int { filter.canceled.count }
    var managerPending: Int { filter.managerPending.count }
    var teamMemberPending: Int { filter.teamMemberPending.count }
    var allPending: Int { filter.allPending.count }
    var active: Int { filter.active.count }
    var overdue: Int { filter.overdue.count }
    
    // MARK: - Outcome Stats
    
    var completedAhead: Int { filter.completedAhead.count }
    var completedJIT: Int { filter.completedJIT.count }
    var completedOverrun: Int { filter.completedOverrun.count }
    
    // MARK: - Priority Stats
    
    var p0Count: Int { filter.p0.count }
    var p1Count: Int { filter.p1.count }
    var p2Count: Int { filter.p2.count }
    var p3Count: Int { filter.p3.count }
    
    // MARK: - Percentage Stats
    
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var overdueRate: Double {
        let activeCount = active
        guard activeCount > 0 else { return 0 }
        return Double(overdue) / Double(activeCount)
    }
    
    var aheadRate: Double {
        guard completed > 0 else { return 0 }
        return Double(completedAhead) / Double(completed)
    }
    
    var onTimeRate: Double {
        guard completed > 0 else { return 0 }
        return Double(completedJIT) / Double(completed)
    }
    
    var overrunRate: Double {
        guard completed > 0 else { return 0 }
        return Double(completedOverrun) / Double(completed)
    }
    
    // MARK: - Summary
    
    /// Returns a summary dictionary of all stats
    var summary: [String: Int] {
        [
            "total": total,
            "running": running,
            "completed": completed,
            "canceled": canceled,
            "pending": allPending,
            "overdue": overdue,
            "ahead": completedAhead,
            "jit": completedJIT,
            "overrun": completedOverrun
        ]
    }
}

// MARK: - Team Extension

extension Team {
    /// Creates ActivityStats for all team activities
    var activityStats: ActivityStats {
        ActivityStats(activities: activities)
    }
}

// MARK: - Array Extension

extension Array where Element == Activity {
    /// Creates ActivityStats for this array of activities
    var stats: ActivityStats {
        ActivityStats(activities: self)
    }
}


//
//  ActivityDataProviding.swift
//  Shared
//
//  Created by Vlad on 2025-12-09.
//

import Foundation

/// Protocol for components that provide access to Team and Activity data.
/// Provides default implementations for filters and statistics.
protocol ActivityDataProviding {
    var team: Team { get }
}

extension ActivityDataProviding {

    // MARK: - Core Helpers

    var activityStats: ActivityStats {
        team.activityStats
    }

    // MARK: - Activity Lists

    var activeActivities: [Activity] {
        team.activities.active
    }

    var completedActivities: [Activity] {
        team.activities.completed
    }

    var canceledActivities: [Activity] {
        team.activities.canceled
    }

    // Note: "Pending" means different things for Manager (ManagerPending) vs TeamMember (AllPending or TeamMemberPending)
    // We can expose the specific ones:

    var managerPendingActivities: [Activity] {
        team.activities.managerPending
    }

    var teamMemberPendingActivities: [Activity] {
        team.activities.teamMemberPending
    }

    var allPendingActivities: [Activity] {
        team.activities.allPending
    }

    var runningActivities: [Activity] {
        team.activities.running
    }

    // MARK: - Stats Counts

    var totalActivitiesCount: Int { team.activities.count }
    var runningCount: Int { team.activities.running.count }
    var activeCount: Int { team.activities.active.count }
    var completedCount: Int { team.activities.completed.count }
    var allPendingCount: Int { team.activities.allPending.count }
    var managerPendingCount: Int { team.activities.managerPending.count }

    var completedAheadCount: Int { team.activities.completedAhead.count }
    var completedJITCount: Int { team.activities.completedJIT.count }
    var completedOverrunCount: Int { team.activities.completedOverrun.count }
}

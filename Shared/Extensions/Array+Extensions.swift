//
//  Array+Extensions.swift
//  Shared
//
//  Helper methods for finding elements in model arrays.
//  Eliminates inline firstIndex(where:) and first(where:) calls.
//
//  Created by vlad on 2025-12-08.
//

import Foundation

// MARK: - Team Array Extensions

extension Array where Element == Team {
    /// Finds a team by its ID
    /// - Parameter id: The team ID to search for
    /// - Returns: The team if found, nil otherwise
    func findTeam(byId id: UUID) -> Team? {
        first { $0.id == id }
    }

    /// Finds the index of a team by its ID
    /// - Parameter id: The team ID to search for
    /// - Returns: The index if found, nil otherwise
    func findTeamIndex(byId id: UUID) -> Int? {
        firstIndex { $0.id == id }
    }

    /// Finds the team that contains a specific activity
    /// - Parameter activityId: The activity ID to search for
    /// - Returns: The team containing the activity, nil if not found
    func findTeam(containingActivityId activityId: UUID) -> Team? {
        first { team in
            team.activities.contains { $0.id == activityId }
        }
    }

    /// Finds the index of the team that contains a specific activity
    /// - Parameter activityId: The activity ID to search for
    /// - Returns: The team index if found, nil otherwise
    func findTeamIndex(containingActivityId activityId: UUID) -> Int? {
        firstIndex { team in
            team.activities.contains { $0.id == activityId }
        }
    }

    /// Finds the team that contains a specific member
    /// - Parameter memberId: The member ID to search for
    /// - Returns: The team containing the member, nil if not found
    func findTeam(containingMemberId memberId: UUID) -> Team? {
        first { team in
            team.members.contains { $0.id == memberId }
        }
    }
}

// MARK: - Activity Array Extensions

extension Array where Element == Activity {
    /// Finds an activity by its ID
    /// - Parameter id: The activity ID to search for
    /// - Returns: The activity if found, nil otherwise
    func findActivity(byId id: UUID) -> Activity? {
        first { $0.id == id }
    }

    /// Finds the index of an activity by its ID
    /// - Parameter id: The activity ID to search for
    /// - Returns: The index if found, nil otherwise
    func findActivityIndex(byId id: UUID) -> Int? {
        firstIndex { $0.id == id }
    }
}

// MARK: - TeamMember Array Extensions

extension Array where Element == TeamMember {
    /// Finds a team member by their name
    /// - Parameter name: The member name to search for
    /// - Returns: The team member if found, nil otherwise
    func findMember(byName name: String) -> TeamMember? {
        first { $0.name == name }
    }

    /// Finds the index of a team member by their name
    /// - Parameter name: The member name to search for
    /// - Returns: The index if found, nil otherwise
    func findMemberIndex(byName name: String) -> Int? {
        firstIndex { $0.name == name }
    }
}

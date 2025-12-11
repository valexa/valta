//
//  TestDataFactory.swift
//  Tests Support
//
//  Shared helpers for creating deterministic test data across test targets.
//  Provides factory methods for TeamMember, Activity, and Team with sensible defaults.
//
//  Created by Assistant on 2025-12-09.
//

import Foundation

@testable import valta

typealias AppTeamMember = valta.TeamMember
typealias AppActivity = valta.Activity
typealias AppTeam = valta.Team
typealias AppActivityStatus = valta.ActivityStatus
typealias AppActivityPriority = valta.ActivityPriority
typealias AppActivityOutcome = valta.ActivityOutcome

enum TestDataFactory {
    // Fixed base date for deterministic tests
    static let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

    // MARK: - Members
    
    static func makeMember(
        id: UUID = UUID(),
        name: String = "Alice",
        email: String? = nil
    ) -> AppTeamMember {
        // Auto-generate email from name if not provided (e.g., "Alice" -> "alice@example.com")
        let memberEmail = email ?? "\(name.lowercased())@example.com"
        return AppTeamMember(id: id, name: name, email: memberEmail)
    }

    // MARK: - Activities

    static func makeActivity(
        id: UUID = UUID(),
        name: String = "Test Activity",
        description: String = "Description",
        assignedMember: AppTeamMember? = nil,
        priority: AppActivityPriority = .p1,
        status: AppActivityStatus = .teamMemberPending,
        outcome: AppActivityOutcome? = nil,
        createdAt: Date = baseDate,
        deadline: Date = baseDate.addingTimeInterval(60 * 60),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        managerEmail: String? = "manager@example.com"
    ) -> AppActivity {
        let member = assignedMember ?? makeMember(name: "Bob", email: "bob@example.com")
        return AppActivity(
            id: id,
            name: name,
            description: description,
            assignedMember: member,
            priority: priority,
            status: status,
            outcome: outcome,
            createdAt: createdAt,
            deadline: deadline,
            startedAt: startedAt,
            completedAt: completedAt,
            managerEmail: managerEmail
        )
    }

    // MARK: - Teams

    static func makeTeam(
        id: UUID = UUID(),
        name: String = "Test Team",
        members: [AppTeamMember] = [],
        activities: [AppActivity] = [],
        managerEmail: String? = "manager@example.com"
    ) -> AppTeam {
        AppTeam(
            id: id,
            name: name,
            members: members,
            activities: activities,
            createdAt: baseDate,
            managerEmail: managerEmail
        )
    }
    
    // MARK: - Convenience Collections

    /// Creates a list of running activities assigned to an optional member
    static func makeRunning(_ count: Int, assignedTo member: AppTeamMember? = nil) -> [AppActivity] {
        (0..<count).map { _ in
            makeActivity(assignedMember: member, status: .running)
        }
    }

    /// Creates completed activities with specified outcome counts, assigned to an optional member
    static func makeCompleted(
        ahead: Int = 0,
        jit: Int = 0,
        overrun: Int = 0,
        assignedTo member: AppTeamMember? = nil
    ) -> [AppActivity] {
        var result: [AppActivity] = []
        result += (0..<ahead).map { _ in makeActivity(assignedMember: member, status: .completed, outcome: .ahead) }
        result += (0..<jit).map { _ in makeActivity(assignedMember: member, status: .completed, outcome: .jit) }
        result += (0..<overrun).map { _ in makeActivity(assignedMember: member, status: .completed, outcome: .overrun) }
        return result
    }

    /// Creates pending activities for team member and manager, assigned to an optional member
    static func makePending(
        teamMember: Int = 0,
        manager: Int = 0,
        assignedTo member: AppTeamMember? = nil
    ) -> [AppActivity] {
        var result: [AppActivity] = []
        result += (0..<teamMember).map { _ in makeActivity(assignedMember: member, status: .teamMemberPending) }
        result += (0..<manager).map { _ in makeActivity(assignedMember: member, status: .managerPending) }
        return result
    }

    /// Creates a team with activities based on counts for each category
    static func makeTeamWithCounts(
        member: AppTeamMember? = nil,
        running: Int = 0,
        completedAhead: Int = 0,
        completedJIT: Int = 0,
        completedOverrun: Int = 0,
        pendingTeamMember: Int = 0,
        pendingManager: Int = 0
    ) -> AppTeam {
        let assigned = member ?? makeMember(name: "Member")
        var activities: [AppActivity] = []
        activities += makeRunning(running, assignedTo: assigned)
        activities += makeCompleted(ahead: completedAhead, jit: completedJIT, overrun: completedOverrun, assignedTo: assigned)
        activities += makePending(teamMember: pendingTeamMember, manager: pendingManager, assignedTo: assigned)
        return makeTeam(members: [assigned], activities: activities)
    }
}

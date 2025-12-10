//
//  Models.swift
//  Shared
//
//  Data models shared between valtaManager and valta (team member) apps.
//  Contains: ActivityStatus, ActivityPriority, ActivityOutcome enums
//  and Activity, TeamMember, Team structs.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Enums

public enum ActivityStatus: String, Codable, Equatable, Hashable, CaseIterable {
    case running = "Running"
    case completed = "Completed"
    case canceled = "Canceled"
    case managerPending = "Manager Pending"
    case teamMemberPending = "Team Member Pending"
    
    var icon: String {
        switch self {
        case .running: return AppSymbols.running
        case .completed: return AppSymbols.completed
        case .canceled: return AppSymbols.canceled
        case .managerPending: return AppSymbols.managerPending
        case .teamMemberPending: return AppSymbols.teamMemberPending
        }
    }
    
    var color: Color {
        switch self {
        case .running: return AppColors.statusRunning
        case .completed: return AppColors.statusCompleted
        case .canceled: return AppColors.statusCanceled
        case .managerPending: return AppColors.statusManagerPending
        case .teamMemberPending: return AppColors.statusTeamMemberPending
        }
    }
}

public enum ActivityPriority: Int, Codable, Equatable, Hashable, CaseIterable, Comparable {
    case p0 = 0
    case p1 = 1
    case p2 = 2
    case p3 = 3
    
    public static func < (lhs: ActivityPriority, rhs: ActivityPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    var displayName: String {
        switch self {
        case .p0: return "P0 - Critical"
        case .p1: return "P1 - High"
        case .p2: return "P2 - Medium"
        case .p3: return "P3 - Low"
        }
    }
    
    var shortName: String {
        switch self {
        case .p0: return "P0"
        case .p1: return "P1"
        case .p2: return "P2"
        case .p3: return "P3"
        }
    }

    var icon: String {
        switch self {
        case .p0: return AppSymbols.flagFill
        case .p1: return AppSymbols.flag
        case .p2: return AppSymbols.flag
        case .p3: return AppSymbols.flagSlash
        }
    }

    var color: Color {
        switch self {
        case .p0: return AppColors.priorityP0
        case .p1: return AppColors.priorityP1
        case .p2: return AppColors.priorityP2
        case .p3: return AppColors.priorityP3
        }
    }
}

public enum ActivityOutcome: String, Codable, Equatable, Hashable, CaseIterable {
    case ahead = "Ahead"
    case jit = "Just In Time"
    case overrun = "Overrun"
    
    var color: Color {
        switch self {
        case .ahead: return AppColors.outcomeAhead
        case .jit: return AppColors.outcomeJIT
        case .overrun: return AppColors.outcomeOverrun
        }
    }
    
    var icon: String {
        switch self {
        case .ahead: return AppSymbols.outcomeAhead
        case .jit: return AppSymbols.outcomeJIT
        case .overrun: return AppSymbols.outcomeOverrun
        }
    }
}

// MARK: - Models

struct TeamMember: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var email: String
    
    init(id: UUID = UUID(), name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }
    
    /// Neutral avatar color for all members
    static let avatarColor = AppColors.avatar
}

struct Activity: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var assignedMember: TeamMember
    var priority: ActivityPriority
    var status: ActivityStatus
    var outcome: ActivityOutcome?
    var createdAt: Date
    var deadline: Date
    var startedAt: Date?
    var completedAt: Date?
    var managerEmail: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        assignedMember: TeamMember,
        priority: ActivityPriority,
        status: ActivityStatus = .teamMemberPending,
        outcome: ActivityOutcome? = nil,
        createdAt: Date = Date(),
        deadline: Date,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        managerEmail: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.assignedMember = assignedMember
        self.priority = priority
        self.status = status
        self.outcome = outcome
        self.createdAt = createdAt
        self.deadline = deadline
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.managerEmail = managerEmail
    }
    
    // MARK: - Time Calculations (delegated to ActivityTimeCalculator)
    
    var timeRemaining: String {
        timeCalculator.timeRemaining
    }
    
    var isOverdue: Bool {
        timeCalculator.isOverdue
    }
    
    var timeProgress: Double {
        timeCalculator.timeProgress
    }
    
    var timeRemainingProgress: Double {
        timeCalculator.timeRemainingProgress
    }
    
}

struct Team: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [TeamMember]
    var activities: [Activity]
    var createdAt: Date
    var managerEmail: String?
    
    init(id: UUID = UUID(), name: String, members: [TeamMember] = [], activities: [Activity] = [], createdAt: Date = Date(), managerEmail: String? = nil) {
        self.id = id
        self.name = name
        self.members = members
        self.activities = activities
        self.createdAt = createdAt
        self.managerEmail = managerEmail
    }
}


// MARK: - Activity Log Entry (for team member app)

struct ActivityLogEntry: Identifiable, Codable {
    let id: UUID
    let activity: Activity
    let action: LogAction
    let timestamp: Date
    let performedBy: String
    
    enum LogAction: String, Codable {
        case created = "Created"
        case started = "Started"
        case completionRequested = "Completion Requested"
        case completed = "Completed"
        case canceled = "Canceled"
    }
    
    init(id: UUID = UUID(), activity: Activity, action: LogAction, timestamp: Date = Date(), performedBy: String) {
        self.id = id
        self.activity = activity
        self.action = action
        self.timestamp = timestamp
        self.performedBy = performedBy
    }
}

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
        completedAt: Date? = nil
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
    }
    
    /// Returns the display color based on status, priority, outcome, and special rules
    var displayColor: Color {
        // For pending statuses, always use the status color (not outcome color)
        if status == .managerPending {
            return AppColors.statusManagerPending
        }
        if status == .teamMemberPending {
            return AppColors.statusTeamMemberPending
        }
        
        // Exception: For p0 activities if outcome is jit (on-time), color is red
        if priority == .p0, let outcome = outcome, outcome == .jit {
            return AppColors.destructive
        }
        
        // For completed activities, show outcome color
        if let outcome = outcome {
            return outcome.color
        }
        
        return status.color
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
    
    /// Calculates the outcome based on completion time vs deadline
    /// - Parameter completionDate: The date of completion (defaults to now)
    /// - Returns: The calculated outcome (Ahead, JIT, or Overrun)
    /// 
    /// Outcomes:
    /// - Ahead: Completed ≥30 min before deadline
    /// - Just In Time: Completed within ±5 min of deadline (before or after)
    /// - Overrun: Completed >5 min after deadline
    func calculateOutcome(completionDate: Date = Date()) -> ActivityOutcome {
        let timeDifference = (completedAt ?? completionDate).timeIntervalSince(deadline)

        // Constants for outcome thresholds
        let aheadThreshold: TimeInterval = 30 * 60  // 30 minutes in seconds
        let jitWindow: TimeInterval = 5 * 60        // 5 minutes in seconds
        
        // Overrun: completed more than 5 minutes after deadline
        if timeDifference > jitWindow {
            return .overrun
        }
        
        // Just In Time: completed within ±5 minutes of deadline
        if abs(timeDifference) <= jitWindow {
            return .jit
        }
        
        // Ahead: completed at least 30 minutes before deadline
        // (timeDifference is negative when before deadline)
        if timeDifference <= -aheadThreshold {
            return .ahead
        }
        
        // Edge case: completed between 5-30 minutes before deadline
        // Classify as JIT since it's not explicitly Ahead (≥30 min) and not within ±5 min
        // This ensures all cases are covered
        return .jit
    }
    
    // MARK: - Backend Updates
    
    /// Updates this activity in the backend (DataManager)
    /// - Parameter mutation: Closure to modify the activity
    @MainActor
    func updateInBackend(_ mutation: (inout Activity) -> Void) {
        let dataManager = DataManager.shared
        
        // Find the team containing this activity
        guard let teamIndex = dataManager.teams.firstIndex(where: { team in
            team.activities.contains(where: { $0.id == self.id })
        }) else {
            print("Error: Could not find team for activity \(self.name)")
            return
        }
        
        // Find the activity index
        guard let activityIndex = dataManager.teams[teamIndex].activities.firstIndex(where: { $0.id == self.id }) else {
            print("Error: Could not find activity \(self.name) in team")
            return
        }
        
        // Apply mutation
        mutation(&dataManager.teams[teamIndex].activities[activityIndex])
        
        // Notify observers immediately
        dataManager.notifyTeamsChanged()
        
        // Sync
        Task {
            await dataManager.syncActivities()
        }
    }
}

struct Team: Identifiable, Codable {
    let id: UUID
    var name: String
    var members: [TeamMember]
    var activities: [Activity]
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, members: [TeamMember] = [], activities: [Activity] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.members = members
        self.activities = activities
        self.createdAt = createdAt
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


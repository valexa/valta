//
//  ActivityEnums.swift
//  LiveTeamCore
//
//  Created by Live Team on 2025-12-04.
//
//  Contains enums defining ActivityStatus, ActivityPriority, ActivityOutcome.
//
//  Spec reference:
//  - Data Model, Enums section
//  - Outcome thresholds: ahead ≥ 30 min early, jit within ±5 min of deadline (to confirm)
//
//  Thread safety:
//  - Pure enums, no state, safe for use across threads.
//

import Foundation

public enum ActivityStatus: String, Codable, Equatable, Hashable {
    case running
    case completed
    case canceled
    case managerPending
    case teamMemberPending
}

public enum ActivityPriority: Int, Codable, Equatable, Hashable, CaseIterable, Comparable {
    case p0 = 0
    case p1 = 1
    case p2 = 2
    case p3 = 3

    public static func < (lhs: ActivityPriority, rhs: ActivityPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

public enum ActivityOutcome: String, Codable, Equatable, Hashable {
    case ahead
    case jit
    case overrun
}

//
//  OutcomeProjectionService.swift
//  Shared
//
//  Provides outcome projections based on historical member performance.
//  Uses statistical analysis of past activities to predict likely outcomes
//  for each team member at different priority levels.
//
//  Created by vlad on 2025-12-19.
//

import Foundation

// MARK: - Projection Result

/// Represents a predicted outcome distribution for a member/priority combination
struct OutcomeProjection: Identifiable {
    let id = UUID()
    let member: TeamMember
    let priority: ActivityPriority
    let aheadProbability: Double
    let jitProbability: Double
    let overrunProbability: Double
    let sampleSize: Int

    /// The most likely outcome based on historical data
    var predictedOutcome: ActivityOutcome {
        if aheadProbability >= jitProbability && aheadProbability >= overrunProbability {
            return .ahead
        } else if jitProbability >= overrunProbability {
            return .jit
        } else {
            return .overrun
        }
    }

    /// Confidence level based on sample size
    var confidence: ProjectionConfidence {
        switch sampleSize {
        case 0: return .noData
        case 1...2: return .veryLow
        case 3...5: return .low
        case 6...10: return .medium
        default: return .high
        }
    }
}

enum ProjectionConfidence: String {
    case noData = "No Data"
    case veryLow = "Very Low"
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var description: String { rawValue }
}

// MARK: - Member Performance Summary

/// Summary of a team member's historical performance
struct MemberPerformanceSummary: Identifiable {
    let id = UUID()
    let member: TeamMember
    let totalCompleted: Int
    let aheadCount: Int
    let jitCount: Int
    let overrunCount: Int
    let projections: [OutcomeProjection]

    var aheadRate: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(aheadCount) / Double(totalCompleted)
    }

    var jitRate: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(jitCount) / Double(totalCompleted)
    }

    var overrunRate: Double {
        guard totalCompleted > 0 else { return 0 }
        return Double(overrunCount) / Double(totalCompleted)
    }

    /// Overall performance score (0-100)
    /// Ahead = 100 points, JIT = 70 points, Overrun = 30 points
    var performanceScore: Double {
        guard totalCompleted > 0 else { return 0 }
        let score = (Double(aheadCount) * 100 + Double(jitCount) * 70 + Double(overrunCount) * 30) / Double(totalCompleted)
        return score
    }
}

// MARK: - Outcome Projection Service

/// Service that analyzes historical activity data to predict future outcomes
struct OutcomeProjectionService {

    /// Generate projections for all team members based on historical data
    /// - Parameter activities: All activities to analyze
    /// - Parameter members: Team members to generate projections for
    /// - Returns: Array of performance summaries with projections
    static func generateProjections(activities: [Activity], members: [TeamMember]) -> [MemberPerformanceSummary] {
        members.map { member in
            generateMemberSummary(for: member, from: activities)
        }
        .sorted { $0.performanceScore > $1.performanceScore }
    }

    /// Generate a performance summary with projections for a single member
    private static func generateMemberSummary(for member: TeamMember, from activities: [Activity]) -> MemberPerformanceSummary {
        // Filter completed activities for this member
        let memberActivities = activities.filter {
            $0.assignedMember.id == member.id && $0.status == .completed && $0.outcome != nil
        }

        // Count outcomes
        let aheadCount = memberActivities.filter { $0.outcome == .ahead }.count
        let jitCount = memberActivities.filter { $0.outcome == .jit }.count
        let overrunCount = memberActivities.filter { $0.outcome == .overrun }.count

        // Generate projections for each priority
        let projections = ActivityPriority.allCases.map { priority in
            generateProjection(for: member, priority: priority, from: activities)
        }

        return MemberPerformanceSummary(
            member: member,
            totalCompleted: memberActivities.count,
            aheadCount: aheadCount,
            jitCount: jitCount,
            overrunCount: overrunCount,
            projections: projections
        )
    }

    /// Generate outcome projection for a specific member and priority level
    private static func generateProjection(
        for member: TeamMember,
        priority: ActivityPriority,
        from activities: [Activity]
    ) -> OutcomeProjection {
        // Filter completed activities for this member and priority
        let relevantActivities = activities.filter {
            $0.assignedMember.id == member.id &&
            $0.priority == priority &&
            $0.status == .completed &&
            $0.outcome != nil
        }

        let sampleSize = relevantActivities.count

        guard sampleSize > 0 else {
            // No data - return equal probabilities
            return OutcomeProjection(
                member: member,
                priority: priority,
                aheadProbability: 0.33,
                jitProbability: 0.34,
                overrunProbability: 0.33,
                sampleSize: 0
            )
        }

        // Calculate probabilities based on historical data
        let aheadCount = Double(relevantActivities.filter { $0.outcome == .ahead }.count)
        let jitCount = Double(relevantActivities.filter { $0.outcome == .jit }.count)
        let overrunCount = Double(relevantActivities.filter { $0.outcome == .overrun }.count)
        let total = Double(sampleSize)

        return OutcomeProjection(
            member: member,
            priority: priority,
            aheadProbability: aheadCount / total,
            jitProbability: jitCount / total,
            overrunProbability: overrunCount / total,
            sampleSize: sampleSize
        )
    }

    /// Get a projection for a specific member and priority
    static func predict(
        for member: TeamMember,
        priority: ActivityPriority,
        from activities: [Activity]
    ) -> OutcomeProjection {
        generateProjection(for: member, priority: priority, from: activities)
    }
}

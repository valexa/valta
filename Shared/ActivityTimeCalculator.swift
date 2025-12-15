//
//  ActivityTimeCalculator.swift
//  Shared
//
//  Extracted time calculation logic for activities.
//  Follows Single Responsibility Principle - handles only time-related calculations.
//
//  Created by vlad on 2025-12-04.
//

import Foundation

// MARK: - Activity Time Calculator

/// Handles all time-related calculations for an activity.
/// Extracted from Activity struct following Single Responsibility Principle.
struct ActivityTimeCalculator {

    // MARK: - Properties

    let createdAt: Date
    let deadline: Date
    let startedAt: Date?
    let completedAt: Date?
    let status: ActivityStatus

    /// Current date provider for testability
    var now: () -> Date = { Date() }

    // MARK: - Initialization

    init(activity: Activity) {
        self.createdAt = activity.createdAt
        self.deadline = activity.deadline
        self.startedAt = activity.startedAt
        self.completedAt = activity.completedAt
        self.status = activity.status
    }

    init(
        createdAt: Date,
        deadline: Date,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        status: ActivityStatus
    ) {
        self.createdAt = createdAt
        self.deadline = deadline
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.status = status
    }

    // MARK: - Time Remaining

    /// Returns the time remaining until deadline as a human-readable string
    var timeRemaining: String {
        let currentDate = now()
        let remaining = deadline.timeIntervalSince(currentDate)

        if remaining < 0 {
            return formatOverdue(abs(remaining))
        } else {
            return formatRemaining(remaining)
        }
    }

    /// Raw time interval remaining (negative if overdue)
    var timeRemainingInterval: TimeInterval {
        deadline.timeIntervalSince(now())
    }

    // MARK: - Overdue Status

    /// Whether the activity is past its deadline and not completed/canceled
    var isOverdue: Bool {
        deadline < now() && status != .completed && status != .canceled
    }

    // MARK: - Progress Calculations

    /// The reference start date for progress calculation.
    /// Uses `startedAt` if available, otherwise falls back to `createdAt`.
    private var progressStartDate: Date {
        startedAt ?? createdAt
    }

    /// Progress percentage (0.0 to 1.0) based on time elapsed from start to deadline.
    /// - Uses `startedAt` as reference if activity has been started
    /// - Falls back to `createdAt` for pending activities
    var timeProgress: Double {
        let currentDate = now()
        let totalDuration = deadline.timeIntervalSince(progressStartDate)
        let elapsed = currentDate.timeIntervalSince(progressStartDate)

        guard totalDuration > 0 else { return 1.0 }

        let progress = elapsed / totalDuration
        return min(max(progress, 0.0), 1.0)
    }

    /// Time remaining as a percentage (1.0 = full time left, 0.0 = deadline reached)
    var timeRemainingProgress: Double {
        max(1.0 - timeProgress, 0.0)
    }

    // MARK: - Completion Time Delta

    /// Time difference between completion and deadline.
    /// Positive means completed before deadline (ahead), negative means after (overrun).
    var completionDelta: TimeInterval? {
        guard let completedAt = completedAt else { return nil }
        return deadline.timeIntervalSince(completedAt)
    }

    /// Formatted completion delta string (e.g., "-2d 3h 15m" for ahead, "+1d 0h 30m" for late)
    var completionDeltaFormatted: String? {
        guard let delta = completionDelta else { return nil }
        return formatDelta(delta)
    }

    // MARK: - Duration Calculations

    /// Total duration from creation to deadline (for reference)
    var totalDurationFromCreation: TimeInterval {
        deadline.timeIntervalSince(createdAt)
    }

    /// Total duration from start to deadline (used for progress calculation)
    var totalDurationFromStart: TimeInterval {
        deadline.timeIntervalSince(progressStartDate)
    }

    /// Duration from start to completion (if both exist)
    var activeDuration: TimeInterval? {
        guard let startedAt = startedAt else { return nil }
        let endDate = completedAt ?? now()
        return endDate.timeIntervalSince(startedAt)
    }

    // MARK: - Current Status Duration

    /// Duration in current status (live for running activities)
    var currentStatusDuration: TimeInterval {
        let currentDate = now()

        switch status {
        case .teamMemberPending:
            // Time waiting since created
            return currentDate.timeIntervalSince(createdAt)
        case .running:
            // Time since started
            guard let startedAt = startedAt else {
                return currentDate.timeIntervalSince(createdAt)
            }
            return currentDate.timeIntervalSince(startedAt)
        case .managerPending:
            // Time since started (approximates time waiting for approval)
            guard let startedAt = startedAt else {
                return currentDate.timeIntervalSince(createdAt)
            }
            return currentDate.timeIntervalSince(startedAt)
        case .completed, .canceled:
            // Final duration from start to completion
            guard let startedAt = startedAt else { return 0 }
            guard let completedAt = completedAt else {
                return currentDate.timeIntervalSince(startedAt)
            }
            return completedAt.timeIntervalSince(startedAt)
        }
    }

    /// Formatted current status duration (e.g., "2h 15m", "3d 4h")
    var currentStatusDurationFormatted: String {
        formatDuration(currentStatusDuration)
    }

    // MARK: - Private Formatting Helpers

    private func formatDuration(_ interval: TimeInterval) -> String {
        let absSeconds = abs(interval)

        let days = Int(absSeconds / 86400)
        let hours = Int((absSeconds.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((absSeconds.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatOverdue(_ interval: TimeInterval) -> String {
        if interval < 3600 {
            return "Overdue by \(Int(interval / 60))m"
        } else if interval < 86400 {
            return "Overdue by \(Int(interval / 3600))h"
        } else {
            return "Overdue by \(Int(interval / 86400))d"
        }
    }

    private func formatRemaining(_ interval: TimeInterval) -> String {
        if interval < 3600 {
            return "\(Int(interval / 60))m left"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h left"
        } else {
            return "\(Int(interval / 86400))d left"
        }
    }

    private func formatDelta(_ delta: TimeInterval) -> String {
        let absSeconds = abs(delta)

        let days = Int(absSeconds / 86400)
        let hours = Int((absSeconds.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((absSeconds.truncatingRemainder(dividingBy: 3600)) / 60)

        let sign = delta >= 0 ? "-" : "+"
        return "\(sign)\(days)d \(hours)h \(minutes)m"
    }
}

// MARK: - Activity Extension

extension Activity {
    /// Creates a time calculator for this activity
    var timeCalculator: ActivityTimeCalculator {
        ActivityTimeCalculator(activity: self)
    }
}

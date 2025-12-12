//
//  ActivityTimeCalculatorTests.swift
//  valtaTests
//
//  Unit tests for ActivityTimeCalculator
//
//  Created by vlad on 2025-12-12.
//

import Testing
import Foundation
@testable import valta

struct ActivityTimeCalculatorTests {
    var mockMember: TeamMember
    var fixedNow: Date

    init() {
        mockMember = TeamMember(name: "Test User", email: "test@example.com")
        fixedNow = Date()
    }

    // MARK: - Time Remaining Tests

    @Test func testTimeRemaining_Minutes() {
        let deadline = fixedNow.addingTimeInterval(30 * 60) // 30 minutes
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-3600),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemaining.contains("30m left"))
    }

    @Test func testTimeRemaining_Hours() {
        let deadline = fixedNow.addingTimeInterval(5 * 3600) // 5 hours
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-3600),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemaining.contains("5h left"))
    }

    @Test func testTimeRemaining_Days() {
        let deadline = fixedNow.addingTimeInterval(3 * 86400) // 3 days
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-3600),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemaining.contains("3d left"))
    }

    @Test func testTimeRemaining_OverdueMinutes() {
        let deadline = fixedNow.addingTimeInterval(-45 * 60) // 45 minutes ago
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemaining.contains("Overdue by 45m"))
    }

    @Test func testTimeRemaining_OverdueHours() {
        let deadline = fixedNow.addingTimeInterval(-2 * 3600) // 2 hours ago
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemaining.contains("Overdue by 2h"))
    }

    // MARK: - IsOverdue Tests

    @Test func testIsOverdue_True() {
        let deadline = fixedNow.addingTimeInterval(-3600) // 1 hour ago
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.isOverdue == true)
    }

    @Test func testIsOverdue_False_FutureDeadline() {
        let deadline = fixedNow.addingTimeInterval(3600) // 1 hour from now
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-3600),
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.isOverdue == false)
    }

    @Test func testIsOverdue_False_WhenCompleted() {
        let deadline = fixedNow.addingTimeInterval(-3600) // Past deadline
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            completedAt: fixedNow.addingTimeInterval(-1800),
            status: .completed
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.isOverdue == false)
    }

    @Test func testIsOverdue_False_WhenCanceled() {
        let deadline = fixedNow.addingTimeInterval(-3600) // Past deadline
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            status: .canceled
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.isOverdue == false)
    }

    // MARK: - Progress Tests

    @Test func testTimeRemainingProgress_HalfwayThrough() {
        let createdAt = fixedNow.addingTimeInterval(-3600) // 1 hour ago
        let deadline = fixedNow.addingTimeInterval(3600) // 1 hour from now
        var calculator = ActivityTimeCalculator(
            createdAt: createdAt,
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        // Should be approximately 0.5 (50% time remaining)
        #expect(calculator.timeRemainingProgress >= 0.49)
        #expect(calculator.timeRemainingProgress <= 0.51)
    }

    @Test func testTimeRemainingProgress_AtDeadline() {
        let createdAt = fixedNow.addingTimeInterval(-3600)
        var calculator = ActivityTimeCalculator(
            createdAt: createdAt,
            deadline: fixedNow, // Deadline is now
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemainingProgress == 0.0)
    }

    @Test func testTimeRemainingProgress_PastDeadline() {
        let createdAt = fixedNow.addingTimeInterval(-7200)
        let deadline = fixedNow.addingTimeInterval(-3600) // 1 hour ago
        var calculator = ActivityTimeCalculator(
            createdAt: createdAt,
            deadline: deadline,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.timeRemainingProgress == 0.0)
    }

    // MARK: - Completion Delta Tests

    @Test func testCompletionDelta_CompletedAhead() {
        let deadline = fixedNow.addingTimeInterval(3600) // 1 hour in future
        let completedAt = fixedNow // Completed now (1 hour early)
        let calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            completedAt: completedAt,
            status: .completed
        )

        #expect(calculator.completionDelta != nil)
        #expect(calculator.completionDelta! > 0) // Positive means ahead
    }

    @Test func testCompletionDelta_CompletedLate() {
        let deadline = fixedNow.addingTimeInterval(-3600) // 1 hour ago
        let completedAt = fixedNow // Completed now (1 hour late)
        let calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-7200),
            deadline: deadline,
            completedAt: completedAt,
            status: .completed
        )

        #expect(calculator.completionDelta != nil)
        #expect(calculator.completionDelta! < 0) // Negative means late
    }

    @Test func testCompletionDelta_NotCompleted() {
        let calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-3600),
            deadline: fixedNow.addingTimeInterval(3600),
            status: .running
        )

        #expect(calculator.completionDelta == nil)
    }

    // MARK: - Duration Tests

    @Test func testActiveDuration_StartedNotCompleted() {
        let startedAt = fixedNow.addingTimeInterval(-7200) // 2 hours ago
        var calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-10800),
            deadline: fixedNow.addingTimeInterval(3600),
            startedAt: startedAt,
            status: .running
        )
        calculator.now = { self.fixedNow }

        #expect(calculator.activeDuration != nil)
        #expect(calculator.activeDuration! >= 7200 - 1) // 2 hours (with some tolerance)
    }

    @Test func testActiveDuration_NotStarted() {
        let calculator = ActivityTimeCalculator(
            createdAt: fixedNow.addingTimeInterval(-3600),
            deadline: fixedNow.addingTimeInterval(3600),
            status: .teamMemberPending
        )

        #expect(calculator.activeDuration == nil)
    }
}

//
//  ActivityModelTests.swift
//  valtaTests
//
//  Unit tests for Activity model logic, specifically outcome calculation.
//
//  Created by Vlad on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct ActivityModelTests {

    // MARK: - Outcome Calculation Tests

    @Test func testCalculateOutcome_Ahead() {
        // Given
        let deadline = Date()
        // Completed 40 minutes before deadline (threshold is 30m)
        let completionDate = deadline.addingTimeInterval(-40 * 60)

        var activity = createActivity(deadline: deadline)
        activity.completedAt = completionDate

        // When
        let outcome = activity.calculateOutcome(completionDate: completionDate)

        // Then
        #expect(outcome == .ahead)
    }

    @Test func testCalculateOutcome_JustInTime_Before() {
        // Given
        let deadline = Date()
        // Completed 4 minutes before deadline (within 5m window)
        let completionDate = deadline.addingTimeInterval(-4 * 60)

        var activity = createActivity(deadline: deadline)
        activity.completedAt = completionDate

        // When
        let outcome = activity.calculateOutcome(completionDate: completionDate)

        // Then
        #expect(outcome == .jit)
    }

    @Test func testCalculateOutcome_JustInTime_After() {
        // Given
        let deadline = Date()
        // Completed 4 minutes after deadline (within 5m window)
        let completionDate = deadline.addingTimeInterval(4 * 60)

        var activity = createActivity(deadline: deadline)
        activity.completedAt = completionDate

        // When
        let outcome = activity.calculateOutcome(completionDate: completionDate)

        // Then
        #expect(outcome == .jit)
    }

    @Test func testCalculateOutcome_Overrun() {
        // Given
        let deadline = Date()
        // Completed 10 minutes after deadline (outside 5m window)
        let completionDate = deadline.addingTimeInterval(10 * 60)

        var activity = createActivity(deadline: deadline)
        activity.completedAt = completionDate

        // When
        let outcome = activity.calculateOutcome(completionDate: completionDate)

        // Then
        #expect(outcome == .overrun)
    }

    @Test func testCalculateOutcome_EdgeCase_BetweenAheadAndJIT() {
        // Given
        let deadline = Date()
        // Completed 20 minutes before deadline
        // (Not >30m ahead, and not within ±5m JIT window)
        // Current logic defaults this to JIT.
        let completionDate = deadline.addingTimeInterval(-20 * 60)

        var activity = createActivity(deadline: deadline)
        activity.completedAt = completionDate

        // When
        let outcome = activity.calculateOutcome(completionDate: completionDate)

        // Then
        #expect(outcome == .jit)
    }

    // MARK: - Helper

    private func createActivity(deadline: Date) -> Activity {
        return Activity(
            name: "Test Activity",
            description: "Desc",
            assignedMember: TeamMember(name: "Test", email: "test@test.com"),
            priority: .p1,
            status: .running,
            deadline: deadline
        )
    }
}

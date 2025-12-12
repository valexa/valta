//
//  ActivityStatsTests.swift
//  valtaTests
//
//  Created by Vlad on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct ActivityStatsTests {

    @Test func testStatsCalculation() {
        let activities =
            TestDataFactory.makeRunning(2) +
            TestDataFactory.makeCompleted(ahead: 2, jit: 1, overrun: 1) +
            TestDataFactory.makePending(teamMember: 1, manager: 1)

        let filter = ActivityFilter(activities: activities)
        let stats = ActivityStats(filter: filter)

        #expect(stats.total == 8)
        #expect(stats.running == 2)
        #expect(stats.completed == 4) // 2 ahead + 1 jit + 1 overrun
        #expect(stats.completedAhead == 2)
        #expect(stats.completedJIT == 1)
        #expect(stats.completedOverrun == 1)

        // pending = teamMemberPending + managerPending
        #expect(stats.allPending == 2)
        #expect(stats.active == 4) // running + pending
    }

    @Test func testEmptyStats() {
        let filter = ActivityFilter(activities: [])
        let stats = ActivityStats(filter: filter)

        #expect(stats.total == 0)
        #expect(stats.active == 0)
        #expect(stats.completed == 0)
    }

    // MARK: - Percentage Calculation Tests

    @Test func testCompletionRate() {
        let activities =
            TestDataFactory.makeCompleted(ahead: 2, jit: 1, overrun: 1) +
            TestDataFactory.makeRunning(4)

        let stats = ActivityStats(activities: activities)

        // 4 completed out of 8 total = 0.5
        #expect(stats.completionRate == 0.5)
    }

    @Test func testAheadRate() {
        let activities = TestDataFactory.makeCompleted(ahead: 3, jit: 1, overrun: 1)
        let stats = ActivityStats(activities: activities)

        // 3 ahead out of 5 completed = 0.6
        #expect(stats.aheadRate == 0.6)
    }

    @Test func testOnTimeRate() {
        let activities = TestDataFactory.makeCompleted(ahead: 1, jit: 2, overrun: 2)
        let stats = ActivityStats(activities: activities)

        // 2 JIT out of 5 completed = 0.4
        #expect(stats.onTimeRate == 0.4)
    }

    @Test func testOverrunRate() {
        let activities = TestDataFactory.makeCompleted(ahead: 1, jit: 1, overrun: 3)
        let stats = ActivityStats(activities: activities)

        // 3 overrun out of 5 completed = 0.6
        #expect(stats.overrunRate == 0.6)
    }

    @Test func testPercentagesWithNoCompleted() {
        let activities = TestDataFactory.makeRunning(5)
        let stats = ActivityStats(activities: activities)

        #expect(stats.completionRate == 0)
        #expect(stats.aheadRate == 0)
        #expect(stats.onTimeRate == 0)
        #expect(stats.overrunRate == 0)
    }

    // MARK: - Summary Tests

    @Test func testSummaryDictionary() {
        let activities =
            TestDataFactory.makeRunning(2) +
            TestDataFactory.makeCompleted(ahead: 1, jit: 1, overrun: 1) +
            TestDataFactory.makePending(teamMember: 1, manager: 0)

        let stats = ActivityStats(activities: activities)
        let summary = stats.summary

        #expect(summary["total"] == 6)
        #expect(summary["running"] == 2)
        #expect(summary["completed"] == 3)
        #expect(summary["pending"] == 1)
        #expect(summary["ahead"] == 1)
        #expect(summary["jit"] == 1)
        #expect(summary["overrun"] == 1)
    }

    // MARK: - Team Extension Test

    @Test func testTeamActivityStats() {
        let member = TeamMember(name: "Test", email: "test@example.com")
        let activities = TestDataFactory.makeCompleted(ahead: 2, jit: 1, overrun: 0)
        var team = Team(name: "Test Team")
        team.activities = activities

        let stats = team.activityStats

        #expect(stats.total == 3)
        #expect(stats.completed == 3)
    }
}


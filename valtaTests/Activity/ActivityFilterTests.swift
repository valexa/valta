//
//  ActivityFilterTests.swift
//  valtaTests
//
//  Unit tests for ActivityFilter
//
//  Created by vlad on 2025-12-05.
//

import Testing
import Foundation
@testable import valta

struct ActivityFilterTests {
    var mockActivities: [Activity]
    var mockMember1: TeamMember
    var mockMember2: TeamMember

    init() {
        mockMember1 = TeamMember(name: "User 1", email: "user1@example.com")
        mockMember2 = TeamMember(name: "User 2", email: "user2@example.com")

        mockActivities = [
            Activity(
                name: "Running Activity",
                description: "Description",
                assignedMember: mockMember1,
                priority: .p0,
                status: .running,
                deadline: Date()
            ),
            Activity(
                name: "Pending Activity",
                description: "Description",
                assignedMember: mockMember1,
                priority: .p1,
                status: .teamMemberPending,
                deadline: Date()
            ),
            Activity(
                name: "Completed Activity",
                description: "Description",
                assignedMember: mockMember2,
                priority: .p2,
                status: .completed,
                outcome: .ahead,
                deadline: Date()
            ),
            Activity(
                name: "Manager Pending Activity",
                description: "Description",
                assignedMember: mockMember1,
                priority: .p0,
                status: .managerPending,
                outcome: .jit,
                deadline: Date()
            ),
            Activity(
                name: "Canceled Activity",
                description: "Description",
                assignedMember: mockMember2,
                priority: .p3,
                status: .canceled,
                deadline: Date()
            )
        ]
    }

    @Test func testRunning() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.running.count == 1)
        #expect(filter.running[0].name == "Running Activity")
    }

    @Test func testTeamMemberPending() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.teamMemberPending.count == 1)
        #expect(filter.teamMemberPending[0].name == "Pending Activity")
    }

    @Test func testManagerPending() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.managerPending.count == 1)
        #expect(filter.managerPending[0].name == "Manager Pending Activity")
    }

    @Test func testCompleted() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.completed.count == 1)
        #expect(filter.completed[0].name == "Completed Activity")
    }

    @Test func testCanceled() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.canceled.count == 1)
        #expect(filter.canceled[0].name == "Canceled Activity")
    }

    @Test func testActive() {
        let filter = ActivityFilter(activities: mockActivities)

        // Active = running + teamMemberPending + managerPending
        #expect(filter.active.count == 3)
    }

    @Test func testAllPending() {
        let filter = ActivityFilter(activities: mockActivities)

        // All pending = teamMemberPending + managerPending
        #expect(filter.allPending.count == 2)
    }

    @Test func testCompletedAhead() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.completedAhead.count == 1)
        #expect(filter.completedAhead[0].outcome == .ahead)
    }

    @Test func testAssignedTo() {
        let filter = ActivityFilter(activities: mockActivities)
        let member1Filter = filter.assignedTo(mockMember1)

        #expect(member1Filter.activities.count == 3)
        #expect(member1Filter.activities.allSatisfy { $0.assignedMember.id == mockMember1.id })
    }

    @Test func testByPriority() {
        let filter = ActivityFilter(activities: mockActivities)
        let p0Activities = filter.byPriority(.p0)

        #expect(p0Activities.count == 2)
        #expect(p0Activities.allSatisfy { $0.priority == .p0 })
    }
}

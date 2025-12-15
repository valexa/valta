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

        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)

        mockActivities = [
            Activity(
                name: "Running Activity",
                description: "Urgent task",
                assignedMember: mockMember1,
                priority: .p0,
                status: .running,
                createdAt: yesterday,
                deadline: tomorrow
            ),
            Activity(
                name: "Pending Activity",
                description: "Description",
                assignedMember: mockMember1,
                priority: .p1,
                status: .teamMemberPending,
                createdAt: now,
                deadline: now
            ),
            Activity(
                name: "Completed Activity",
                description: "Description",
                assignedMember: mockMember2,
                priority: .p2,
                status: .completed,
                outcome: .ahead,
                createdAt: yesterday,
                deadline: tomorrow
            ),
            Activity(
                name: "Manager Pending Activity",
                description: "Description",
                assignedMember: mockMember1,
                priority: .p0,
                status: .managerPending,
                outcome: .jit,
                createdAt: now,
                deadline: yesterday // Overdue
            ),
            Activity(
                name: "Canceled Activity",
                description: "Description",
                assignedMember: mockMember2,
                priority: .p3,
                status: .canceled,
                createdAt: now,
                deadline: now
            )
        ]
    }

    // MARK: - Status Filter Tests

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

    // MARK: - Outcome Filter Tests

    @Test func testCompletedAhead() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.completedAhead.count == 1)
        #expect(filter.completedAhead[0].outcome == .ahead)
    }

    // MARK: - Member Filter Tests

    @Test func testAssignedTo() {
        let filter = ActivityFilter(activities: mockActivities)
        let member1Filter = filter.assignedTo(mockMember1)

        #expect(member1Filter.activities.count == 3)
        #expect(member1Filter.activities.allSatisfy { $0.assignedMember.id == mockMember1.id })
    }

    @Test func testAssignedToById() {
        let filter = ActivityFilter(activities: mockActivities)
        let member2Filter = filter.assignedTo(memberId: mockMember2.id)

        #expect(member2Filter.activities.count == 2)
    }

    // MARK: - Priority Filter Tests

    @Test func testByPriority() {
        let filter = ActivityFilter(activities: mockActivities)
        let p0Activities = filter.byPriority(.p0)

        #expect(p0Activities.count == 2)
        #expect(p0Activities.allSatisfy { $0.priority == .p0 })
    }

    @Test func testPriorityShortcuts() {
        let filter = ActivityFilter(activities: mockActivities)

        #expect(filter.p0.count == 2)
        #expect(filter.p1.count == 1)
        #expect(filter.p2.count == 1)
        #expect(filter.p3.count == 1)
    }

    // MARK: - Search Tests

    @Test func testSearchByName() {
        let filter = ActivityFilter(activities: mockActivities)
        let results = filter.search("Running")

        #expect(results.count == 1)
        #expect(results[0].name == "Running Activity")
    }

    @Test func testSearchByDescription() {
        let filter = ActivityFilter(activities: mockActivities)
        let results = filter.search("Urgent")

        #expect(results.count == 1)
        #expect(results[0].name == "Running Activity")
    }

    @Test func testSearchByMemberName() {
        let filter = ActivityFilter(activities: mockActivities)
        let results = filter.search("User 2")

        #expect(results.count == 2)
    }

    @Test func testSearchCaseInsensitive() {
        let filter = ActivityFilter(activities: mockActivities)
        let results = filter.search("RUNNING")

        #expect(results.count == 1)
    }

    @Test func testSearchEmptyQuery() {
        let filter = ActivityFilter(activities: mockActivities)
        let results = filter.search("")

        #expect(results.count == mockActivities.count)
    }

    // MARK: - Sorting Tests

    @Test func testSortedByPriority() {
        let filter = ActivityFilter(activities: mockActivities)
        let sorted = filter.sortedByPriority()

        #expect(sorted.first?.priority == .p0)
        #expect(sorted.last?.priority == .p3)
    }

    @Test func testSortedByDeadlineAscending() {
        let filter = ActivityFilter(activities: mockActivities)
        let sorted = filter.sortedByDeadline(ascending: true)

        #expect(sorted.first!.deadline <= sorted.last!.deadline)
    }

    @Test func testSortedByDeadlineDescending() {
        let filter = ActivityFilter(activities: mockActivities)
        let sorted = filter.sortedByDeadline(ascending: false)

        #expect(sorted.first!.deadline >= sorted.last!.deadline)
    }

    @Test func testSortedByCreatedAt() {
        let filter = ActivityFilter(activities: mockActivities)
        let sorted = filter.sortedByCreatedAt(ascending: true)

        #expect(sorted.first!.createdAt <= sorted.last!.createdAt)
    }

    // MARK: - Edge Cases

    @Test func testEmptyFilter() {
        let filter = ActivityFilter(activities: [])

        #expect(filter.running.isEmpty)
        #expect(filter.completed.isEmpty)
        #expect(filter.active.isEmpty)
        #expect(filter.search("test").isEmpty)
    }

    @Test func testByStatus() {
        let filter = ActivityFilter(activities: mockActivities)
        let running = filter.byStatus(.running)

        #expect(running.count == 1)
        #expect(running[0].status == .running)
    }

    @Test func testByOutcome() {
        let filter = ActivityFilter(activities: mockActivities)
        let ahead = filter.byOutcome(.ahead)

        #expect(ahead.count == 1)
        #expect(ahead[0].outcome == .ahead)
    }
}

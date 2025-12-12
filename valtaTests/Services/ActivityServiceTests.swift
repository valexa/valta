//
//  ActivityServiceTests.swift
//  valtaTests
//
//  Unit tests for ActivityService
//
//  Created by vlad on 2025-12-05.
//

import Testing
import Foundation
@testable import valta

struct ActivityServiceTests {
    var activityService: ActivityService
    var mockActivities: [Activity]
    var mockMember: TeamMember

    init() {
        activityService = ActivityService()
        mockMember = TeamMember(name: "Test User", email: "test@example.com")

        mockActivities = [
            Activity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "Activity 1",
                description: "Description 1",
                assignedMember: mockMember,
                priority: .p0,
                status: .teamMemberPending,
                deadline: Date()
            ),
            Activity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Activity 2",
                description: "Description 2",
                assignedMember: mockMember,
                priority: .p1,
                status: .running,
                deadline: Date(),
                startedAt: Date()
            ),
            Activity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Activity 3",
                description: "Description 3",
                assignedMember: mockMember,
                priority: .p2,
                status: .managerPending,
                outcome: .jit,
                deadline: Date()
            ),
            Activity(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                name: "Activity 4",
                description: "Description 4",
                assignedMember: mockMember,
                priority: .p3,
                status: .completed,
                outcome: .ahead,
                deadline: Date(),
                completedAt: Date()
            )
        ]
    }

    // MARK: - Start Activity Tests

    @Test func testStartActivity_Success() {
        let activityId = mockActivities[0].id
        var activities = mockActivities

        let updatedActivity = activityService.startActivity(id: activityId, in: &activities)

        #expect(updatedActivity != nil)
        #expect(updatedActivity?.status == .running)
        #expect(updatedActivity?.startedAt != nil)
        #expect(activities[0].status == .running)
    }

    @Test func testStartActivity_NonExistentID() {
        let nonExistentId = UUID()
        var activities = mockActivities

        let updatedActivity = activityService.startActivity(id: nonExistentId, in: &activities)

        #expect(updatedActivity == nil)
    }

    @Test func testStartActivity_InvalidStatus_AlreadyRunning() {
        let activityId = mockActivities[1].id // Already running
        var activities = mockActivities

        let updatedActivity = activityService.startActivity(id: activityId, in: &activities)

        #expect(updatedActivity == nil)
    }

    @Test func testStartActivity_InvalidStatus_Completed() {
        let activityId = mockActivities[3].id // Completed
        var activities = mockActivities

        let updatedActivity = activityService.startActivity(id: activityId, in: &activities)

        #expect(updatedActivity == nil)
    }

    // MARK: - Request Completion Tests

    @Test func testRequestCompletion_Success() {
        let activityId = mockActivities[1].id
        var activities = mockActivities

        let updatedActivity = activityService.requestCompletion(
            id: activityId,
            outcome: .ahead,
            in: &activities
        )

        #expect(updatedActivity != nil)
        #expect(updatedActivity?.status == .managerPending)
        #expect(updatedActivity?.outcome == .ahead)
        #expect(activities[1].status == .managerPending)
    }

    @Test func testRequestCompletion_NonExistentID() {
        let nonExistentId = UUID()
        var activities = mockActivities

        let updatedActivity = activityService.requestCompletion(
            id: nonExistentId,
            outcome: .jit,
            in: &activities
        )

        #expect(updatedActivity == nil)
    }

    @Test func testRequestCompletion_InvalidStatus_NotRunning() {
        let activityId = mockActivities[0].id // teamMemberPending
        var activities = mockActivities

        let updatedActivity = activityService.requestCompletion(
            id: activityId,
            outcome: .ahead,
            in: &activities
        )

        #expect(updatedActivity == nil)
    }

    // MARK: - Approve Completion Tests

    @Test func testApproveCompletion_Success() {
        let activityId = mockActivities[2].id // managerPending
        var activities = mockActivities

        let updatedActivity = activityService.approveCompletion(id: activityId, in: &activities)

        #expect(updatedActivity != nil)
        #expect(updatedActivity?.status == .completed)
        #expect(updatedActivity?.completedAt != nil)
        #expect(activities[2].status == .completed)
    }

    @Test func testApproveCompletion_NonExistentID() {
        let nonExistentId = UUID()
        var activities = mockActivities

        let updatedActivity = activityService.approveCompletion(id: nonExistentId, in: &activities)

        #expect(updatedActivity == nil)
    }

    @Test func testApproveCompletion_InvalidStatus_NotManagerPending() {
        let activityId = mockActivities[1].id // running
        var activities = mockActivities

        let updatedActivity = activityService.approveCompletion(id: activityId, in: &activities)

        #expect(updatedActivity == nil)
    }

    // MARK: - Reject Completion Tests

    @Test func testRejectCompletion_Success() {
        let activityId = mockActivities[2].id // managerPending
        var activities = mockActivities

        let updatedActivity = activityService.rejectCompletion(id: activityId, in: &activities)

        #expect(updatedActivity != nil)
        #expect(updatedActivity?.status == .running)
        #expect(updatedActivity?.outcome == nil) // Outcome should be cleared
        #expect(activities[2].status == .running)
    }

    @Test func testRejectCompletion_NonExistentID() {
        let nonExistentId = UUID()
        var activities = mockActivities

        let updatedActivity = activityService.rejectCompletion(id: nonExistentId, in: &activities)

        #expect(updatedActivity == nil)
    }

    @Test func testRejectCompletion_InvalidStatus_NotManagerPending() {
        let activityId = mockActivities[1].id // running
        var activities = mockActivities

        let updatedActivity = activityService.rejectCompletion(id: activityId, in: &activities)

        #expect(updatedActivity == nil)
    }

    // MARK: - Complete Activity Tests

    @Test func testCompleteActivity_Success() {
        let activityId = mockActivities[1].id
        var activities = mockActivities

        activityService.completeActivity(id: activityId, outcome: .jit, in: &activities)

        #expect(activities[1].status == .completed)
        #expect(activities[1].outcome == .jit)
        #expect(activities[1].completedAt != nil)
    }

    @Test func testCompleteActivity_NonExistentID() {
        let nonExistentId = UUID()
        var activities = mockActivities
        let originalCount = activities.count

        activityService.completeActivity(id: nonExistentId, outcome: .ahead, in: &activities)

        #expect(activities.count == originalCount)
    }

    // MARK: - Cancel Activity Tests

    @Test func testCancelActivity_Success() {
        let activityId = mockActivities[0].id
        var activities = mockActivities

        activityService.cancelActivity(id: activityId, in: &activities)

        #expect(activities[0].status == .canceled)
    }

    @Test func testCancelActivity_NonExistentID() {
        let nonExistentId = UUID()
        var activities = mockActivities
        let originalStatuses = activities.map { $0.status }

        activityService.cancelActivity(id: nonExistentId, in: &activities)

        #expect(activities.map { $0.status } == originalStatuses)
    }

    @Test func testCancelActivity_InvalidStatus_AlreadyCompleted() {
        let activityId = mockActivities[3].id // completed
        var activities = mockActivities

        let result = activityService.cancelActivity(id: activityId, in: &activities)

        #expect(result == nil)
        #expect(activities[3].status == .completed) // Should remain completed
    }
}


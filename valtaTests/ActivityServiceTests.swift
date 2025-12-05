//
//  ActivityServiceTests.swift
//  valtaTests
//
//  Unit tests for ActivityService
//
//  Created by vlad on 2025-12-05.
//

import XCTest
@testable import valta

final class ActivityServiceTests: XCTestCase {
    var activityService: ActivityService!
    var mockActivities: [Activity]!
    var mockMember: TeamMember!
    
    override func setUpWithError() throws {
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
            )
        ]
    }
    
    override func tearDownWithError() throws {
        activityService = nil
        mockActivities = nil
        mockMember = nil
    }
    
    // MARK: - Start Activity Tests
    
    func testStartActivity_Success() throws {
        let activityId = mockActivities[0].id
        var activities = mockActivities!
        
        let updatedActivity = activityService.startActivity(id: activityId, in: &activities)
        
        XCTAssertNotNil(updatedActivity)
        XCTAssertEqual(updatedActivity?.status, .running)
        XCTAssertNotNil(updatedActivity?.startedAt)
        XCTAssertEqual(activities[0].status, .running)
    }
    
    func testStartActivity_NonExistentID() throws {
        let nonExistentId = UUID()
        var activities = mockActivities!
        
        let updatedActivity = activityService.startActivity(id: nonExistentId, in: &activities)
        
        XCTAssertNil(updatedActivity)
    }
    
    // MARK: - Request Completion Tests
    
    func testRequestCompletion_Success() throws {
        let activityId = mockActivities[1].id
        var activities = mockActivities!
        
        let updatedActivity = activityService.requestCompletion(
            id: activityId,
            outcome: .ahead,
            in: &activities
        )
        
        XCTAssertNotNil(updatedActivity)
        XCTAssertEqual(updatedActivity?.status, .managerPending)
        XCTAssertEqual(updatedActivity?.outcome, .ahead)
        XCTAssertEqual(activities[1].status, .managerPending)
    }
    
    func testRequestCompletion_NonExistentID() throws {
        let nonExistentId = UUID()
        var activities = mockActivities!
        
        let updatedActivity = activityService.requestCompletion(
            id: nonExistentId,
            outcome: .jit,
            in: &activities
        )
        
        XCTAssertNil(updatedActivity)
    }
    
    // MARK: - Complete Activity Tests
    
    func testCompleteActivity_Success() throws {
        let activityId = mockActivities[1].id
        var activities = mockActivities!
        
        activityService.completeActivity(id: activityId, outcome: .jit, in: &activities)
        
        XCTAssertEqual(activities[1].status, .completed)
        XCTAssertEqual(activities[1].outcome, .jit)
        XCTAssertNotNil(activities[1].completedAt)
    }
    
    func testCompleteActivity_NonExistentID() throws {
        let nonExistentId = UUID()
        var activities = mockActivities!
        let originalCount = activities.count
        
        activityService.completeActivity(id: nonExistentId, outcome: .ahead, in: &activities)
        
        XCTAssertEqual(activities.count, originalCount)
    }
    
    // MARK: - Cancel Activity Tests
    
    func testCancelActivity_Success() throws {
        let activityId = mockActivities[0].id
        var activities = mockActivities!
        
        activityService.cancelActivity(id: activityId, in: &activities)
        
        XCTAssertEqual(activities[0].status, .canceled)
    }
    
    func testCancelActivity_NonExistentID() throws {
        let nonExistentId = UUID()
        var activities = mockActivities!
        let originalStatuses = activities.map { $0.status }
        
        activityService.cancelActivity(id: nonExistentId, in: &activities)
        
        XCTAssertEqual(activities.map { $0.status }, originalStatuses)
    }
}

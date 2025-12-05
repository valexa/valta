//
//  ActivityFilterTests.swift
//  valtaTests
//
//  Unit tests for ActivityFilter
//
//  Created by vlad on 2025-12-05.
//

import XCTest
@testable import valta

final class ActivityFilterTests: XCTestCase {
    var mockActivities: [Activity]!
    var mockMember1: TeamMember!
    var mockMember2: TeamMember!
    
    override func setUpWithError() throws {
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
    
    override func tearDownWithError() throws {
        mockActivities = nil
        mockMember1 = nil
        mockMember2 = nil
    }
    
    func testRunning() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        XCTAssertEqual(filter.running.count, 1)
        XCTAssertEqual(filter.running[0].name, "Running Activity")
    }
    
    func testTeamMemberPending() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        XCTAssertEqual(filter.teamMemberPending.count, 1)
        XCTAssertEqual(filter.teamMemberPending[0].name, "Pending Activity")
    }
    
    func testManagerPending() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        XCTAssertEqual(filter.managerPending.count, 1)
        XCTAssertEqual(filter.managerPending[0].name, "Manager Pending Activity")
    }
    
    func testCompleted() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        XCTAssertEqual(filter.completed.count, 1)
        XCTAssertEqual(filter.completed[0].name, "Completed Activity")
    }
    
    func testCanceled() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        XCTAssertEqual(filter.canceled.count, 1)
        XCTAssertEqual(filter.canceled[0].name, "Canceled Activity")
    }
    
    func testActive() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        // Active = running + teamMemberPending + managerPending
        XCTAssertEqual(filter.active.count, 3)
    }
    
    func testAllPending() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        // All pending = teamMemberPending + managerPending
        XCTAssertEqual(filter.allPending.count, 2)
    }
    
    func testCompletedAhead() throws {
        let filter = ActivityFilter(activities: mockActivities)
        
        XCTAssertEqual(filter.completedAhead.count, 1)
        XCTAssertEqual(filter.completedAhead[0].outcome, .ahead)
    }
    
    func testAssignedTo() throws {
        let filter = ActivityFilter(activities: mockActivities)
        let member1Filter = filter.assignedTo(mockMember1)
        
        XCTAssertEqual(member1Filter.activities.count, 3)
        XCTAssertTrue(member1Filter.activities.allSatisfy { $0.assignedMember.id == mockMember1.id })
    }
    
    func testByPriority() throws {
        let filter = ActivityFilter(activities: mockActivities)
        let p0Activities = filter.byPriority(.p0)
        
        XCTAssertEqual(p0Activities.count, 2)
        XCTAssertTrue(p0Activities.allSatisfy { $0.priority == .p0 })
    }
}

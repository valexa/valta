//
//  ActivityLogServiceTests.swift
//  valtaTests
//
//  Unit tests for ActivityLogService
//
//  Created by vlad on 2025-12-05.
//

import XCTest
@testable import valta

final class ActivityLogServiceTests: XCTestCase {
    var logService: ActivityLogService!
    var mockMember: TeamMember!
    
    override func setUpWithError() throws {
        logService = ActivityLogService.shared
        mockMember = TeamMember(name: "Test User", email: "test@example.com")
    }
    
    override func tearDownWithError() throws {
        logService = nil
        mockMember = nil
    }
    
    func testGenerateLogEntries_NewActivity() throws {
        let activity = Activity(
            name: "Test Activity",
            description: "Description",
            assignedMember: mockMember,
            priority: .p0,
            status: .teamMemberPending,
            deadline: Date()
        )
        
        let entries = logService.generateLogEntries(from: [activity])
        
        // Should only have "created" entry for new activity
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].action, .created)
    }
    
    func testGenerateLogEntries_StartedActivity() throws {
        let activity = Activity(
            name: "Test Activity",
            description: "Description",
            assignedMember: mockMember,
            priority: .p0,
            status: .running,
            deadline: Date(),
            startedAt: Date()
        )
        
        let entries = logService.generateLogEntries(from: [activity])
        
        // Should have "created" and "started" entries
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.contains(where: { $0.action == .created }))
        XCTAssertTrue(entries.contains(where: { $0.action == .started }))
    }
    
    func testGenerateLogEntries_CompletedActivity() throws {
        let activity = Activity(
            name: "Test Activity",
            description: "Description",
            assignedMember: mockMember,
            priority: .p0,
            status: .completed,
            deadline: Date(),
            startedAt: Date(),
            completedAt: Date()
        )
        
        let entries = logService.generateLogEntries(from: [activity])
        
        // Should have "created", "started", and "completed" entries
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries.contains(where: { $0.action == .created }))
        XCTAssertTrue(entries.contains(where: { $0.action == .started }))
        XCTAssertTrue(entries.contains(where: { $0.action == .completed }))
    }
    
    func testGenerateLogEntries_ManagerPendingActivity() throws {
        let activity = Activity(
            name: "Test Activity",
            description: "Description",
            assignedMember: mockMember,
            priority: .p0,
            status: .managerPending,
            deadline: Date(),
            startedAt: Date()
        )
        
        let entries = logService.generateLogEntries(from: [activity])
        
        // Should have "created", "started", and "completionRequested" entries
        XCTAssertEqual(entries.count, 3)
        XCTAssertTrue(entries.contains(where: { $0.action == .created }))
        XCTAssertTrue(entries.contains(where: { $0.action == .started }))
        XCTAssertTrue(entries.contains(where: { $0.action == .completionRequested }))
    }
    
    func testGenerateLogEntries_CanceledActivity() throws {
        let activity = Activity(
            name: "Test Activity",
            description: "Description",
            assignedMember: mockMember,
            priority: .p0,
            status: .canceled,
            deadline: Date()
        )
        
        let entries = logService.generateLogEntries(from: [activity])
        
        // Should have "created" and "canceled" entries
        XCTAssertEqual(entries.count, 2)
        XCTAssertTrue(entries.contains(where: { $0.action == .created }))
        XCTAssertTrue(entries.contains(where: { $0.action == .canceled }))
    }
    
    func testGenerateLogEntries_SortsByTimestamp() throws {
        let now = Date()
        let earlier = now.addingTimeInterval(-3600)
        let later = now.addingTimeInterval(3600)
        
        let activities = [
            Activity(
                name: "Activity 1",
                description: "Description",
                assignedMember: mockMember,
                priority: .p0,
                status: .running,
                createdAt: earlier,
                deadline: Date(),
                startedAt: now
            ),
            Activity(
                name: "Activity 2",
                description: "Description",
                assignedMember: mockMember,
                priority: .p0,
                status: .completed,
                createdAt: now,
                deadline: Date(),
                startedAt: now,
                completedAt: later
            )
        ]
        
        let entries = logService.generateLogEntries(from: activities)
        
        // Entries should be sorted with most recent first
        XCTAssertTrue(entries[0].timestamp >= entries[1].timestamp)
        for i in 0..<(entries.count - 1) {
            XCTAssertTrue(entries[i].timestamp >= entries[i + 1].timestamp,
                         "Entries should be sorted by timestamp descending")
        }
    }
    
    func testGenerateLogEntries_MultipleActivities() throws {
        let activities = [
            Activity(
                name: "Activity 1",
                description: "Description",
                assignedMember: mockMember,
                priority: .p0,
                status: .teamMemberPending,
                deadline: Date()
            ),
            Activity(
                name: "Activity 2",
                description: "Description",
                assignedMember: mockMember,
                priority: .p1,
                status: .running,
                deadline: Date(),
                startedAt: Date()
            )
        ]
        
        let entries = logService.generateLogEntries(from: activities)
        
        // First activity: 1 entry, Second activity: 2 entries
        XCTAssertEqual(entries.count, 3)
    }
}

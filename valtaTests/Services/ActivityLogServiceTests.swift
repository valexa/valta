//
//  ActivityLogServiceTests.swift
//  valtaTests
//
//  Unit tests for ActivityLogService
//
//  Created by vlad on 2025-12-05.
//

import Testing
import Foundation
@testable import valta

struct ActivityLogServiceTests {
    var logService: ActivityLogService
    var mockMember: TeamMember
    
    init() {
        logService = ActivityLogService.shared
        mockMember = TeamMember(name: "Test User", email: "test@example.com")
    }
    
    @Test func testGenerateLogEntries_NewActivity() {
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
        #expect(entries.count == 1)
        #expect(entries[0].action == .created)
    }
    
    @Test func testGenerateLogEntries_StartedActivity() {
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
        #expect(entries.count == 2)
        #expect(entries.contains(where: { $0.action == .created }))
        #expect(entries.contains(where: { $0.action == .started }))
    }
    
    @Test func testGenerateLogEntries_CompletedActivity() {
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
        #expect(entries.count == 3)
        #expect(entries.contains(where: { $0.action == .created }))
        #expect(entries.contains(where: { $0.action == .started }))
        #expect(entries.contains(where: { $0.action == .completed }))
    }
    
    @Test func testGenerateLogEntries_ManagerPendingActivity() {
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
        #expect(entries.count == 3)
        #expect(entries.contains(where: { $0.action == .created }))
        #expect(entries.contains(where: { $0.action == .started }))
        #expect(entries.contains(where: { $0.action == .completionRequested }))
    }
    
    @Test func testGenerateLogEntries_CanceledActivity() {
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
        #expect(entries.count == 2)
        #expect(entries.contains(where: { $0.action == .created }))
        #expect(entries.contains(where: { $0.action == .canceled }))
    }
    
    @Test func testGenerateLogEntries_SortsByTimestamp() {
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
        #expect(entries[0].timestamp >= entries[1].timestamp)
        for i in 0..<(entries.count - 1) {
            #expect(entries[i].timestamp >= entries[i + 1].timestamp,
                          "Entries should be sorted by timestamp descending")
        }
    }
    
    @Test func testGenerateLogEntries_MultipleActivities() {
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
        #expect(entries.count == 3)
    }
}

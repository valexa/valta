//
//  NotificationSenderTests.swift
//  valtaTests
//
//  Unit tests for NotificationSender
//
//  Created by vlad on 2025-12-05.
//

import Testing
import Foundation
@testable import valta

// MARK: - Mocks

class MockCloudFunctionProvider: CloudFunctionProvider {
    var calls: [(name: String, data: [String: Any])] = []
    var shouldFail: Bool = false
    var errorToThrow: Error = URLError(.unknown)
    
    func call(name: String, data: [String: Any]) async throws -> Any {
        if shouldFail {
            throw errorToThrow
        }
        calls.append((name, data))
        return "success"
    }
}

class MockAuthChecker: AuthChecking {
    var isAuthenticated: Bool = true
}

// MARK: - Tests

@MainActor
struct NotificationSenderTests {
    var sender: NotificationSender
    var mockProvider: MockCloudFunctionProvider
    var mockAuth: MockAuthChecker
    
    // Test Data
    let testMember = TeamMember(id: UUID(), name: "Test User", email: "test@example.com")
    let testTeam = Team(id: UUID(), name: "Test Team", members: [])
    
    init() {
        mockProvider = MockCloudFunctionProvider()
        mockAuth = MockAuthChecker()
        sender = NotificationSender(functionProvider: mockProvider, authChecker: mockAuth)
    }
    
    // MARK: - Activity Assigned Tests
    
    @Test func testSendActivityAssigned_FormatsMessageCorrectly() async throws {
        // Given
        let createdAt = Date(timeIntervalSince1970: 1733400000) // 2024-12-05 12:00:00 UTC
        let deadline = Date(timeIntervalSince1970: 1733486400) // 2024-12-06 12:00:00 UTC
        
        let activity = Activity(
            name: "Test Activity",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .teamMemberPending,
            createdAt: createdAt,
            deadline: deadline
        )
        
        // When
        try await sender.sendActivityAssignedNotification(
            activity: activity,
            assignedTo: testMember,
            managerName: "Manager Bob"
        )
        
        // Then
        #expect(mockProvider.calls.count == 1)
        
        if let call = mockProvider.calls.first {
            #expect(call.name == "sendActivityAssignedNotification")
            
            let data = call.data
            #expect(data["type"] as? String == "activity_assigned")
            #expect(data["activityId"] as? String == activity.id.uuidString)
            #expect(data["assignedMemberEmail"] as? String == testMember.email)
            #expect(data["assignedMemberName"] as? String == testMember.name)
            #expect(data["priority"] as? String == "P0")
            #expect(data["activityName"] as? String == "Test Activity")
            
            let message = data["message"] as? String
            #expect(message != nil)
            #expect(message?.contains("Manager Bob") == true)
            #expect(message?.contains("P0") == true)
        }
    }
    
    // MARK: - Activity Started Tests
    
    @Test func testSendActivityStarted_WithStartedAt() async throws {
        // Given
        let startedAt = Date(timeIntervalSince1970: 1733403600) // 13:00
        let activity = Activity(
            name: "Test Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p1,
            status: .running,
            deadline: Date(),
            startedAt: startedAt
        )
        
        // When
        try await sender.sendActivityStartedNotification(activity: activity, team: testTeam)
        
        // Then
        let call = try #require(mockProvider.calls.first, "Expected a call to cloud function")
        
        #expect(call.name == "sendActivityStartedNotification")
        
        let data = call.data
        #expect(data["type"] as? String == "activity_started")
        #expect(data["activityId"] as? String == activity.id.uuidString)
        #expect(data["teamId"] as? String == testTeam.id.uuidString)
        #expect(data["memberName"] as? String == testMember.name)
        #expect(data["priority"] as? String == "P1")
        #expect(data["activityName"] as? String == "Test Task")
        
        let message = data["message"] as? String
        #expect(message?.contains("Test User") == true)
        #expect(message?.contains("P1") == true)
    }
    
    // MARK: - Completion Requested Tests
    
    @Test func testSendCompletionRequested_WithManagerEmail() async throws {
        // Given
        let managerEmail = "manager@example.com"
        let activity = Activity(
            name: "Important Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p2,
            status: .managerPending,
            deadline: Date(),
            managerEmail: managerEmail
        )
        
        // When
        try await sender.sendCompletionRequestedNotification(activity: activity)
        
        // Then
        let call = try #require(mockProvider.calls.first, "Expected a call to cloud function")

        #expect(call.name == "sendCompletionRequestedNotification")
        
        let data = call.data
        #expect(data["type"] as? String == "completion_requested")
        #expect(data["activityId"] as? String == activity.id.uuidString)
        #expect(data["managerEmail"] as? String == managerEmail)
        #expect(data["memberName"] as? String == testMember.name)
        #expect(data["activityName"] as? String == "Important Task")
        
        let message = data["message"] as? String
        #expect(message?.contains("Test User") == true)
        #expect(message?.contains("Important Task") == true)
    }
    
    @Test func testSendCompletionRequested_WithoutManagerEmail() async throws {
        // Given
        let activity = Activity(
            name: "Important Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p2,
            status: .managerPending,
            deadline: Date(),
            managerEmail: nil
        )
        
        // When
        try await sender.sendCompletionRequestedNotification(activity: activity)
        
        // Then
        let call = try #require(mockProvider.calls.first, "Expected a call to cloud function")
        
        let data = call.data
        #expect(data["managerEmail"] == nil)
    }
    
    // MARK: - Activity Completed Tests
    
    @Test func testSendActivityCompleted_WithOutcome() async throws {
        // Given
        let activity = Activity(
            name: "Done Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .completed,
            outcome: .ahead,
            deadline: Date()
        )
        
        // When
        try await sender.sendActivityCompletedNotification(activity: activity, team: testTeam)
        
        // Then
        let call = try #require(mockProvider.calls.first, "Expected a call to cloud function")
        
        #expect(call.name == "sendActivityCompletedNotification")
        
        let data = call.data
        #expect(data["type"] as? String == "activity_completed")
        #expect(data["activityId"] as? String == activity.id.uuidString)
        #expect(data["teamId"] as? String == testTeam.id.uuidString)
        #expect(data["statusColor"] as? String == "green")
        #expect(data["outcome"] as? String == "Ahead")
        #expect(data["activityName"] as? String == "Done Task")
        
        let message = data["message"] as? String
        #expect(message?.contains("ahead") == true)
        #expect(message?.contains("green") == true)
    }
    
    @Test func testSendActivityCompleted_MissingOutcome_ThrowsError() async {
        // Given
        let activity = Activity(
            name: "Done Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .completed,
            outcome: nil, // Missing outcome
            deadline: Date()
        )
        
        // When/Then
        await #expect(throws: NotificationError.missingOutcome) {
            try await sender.sendActivityCompletedNotification(activity: activity, team: testTeam)
        }
    }
    
    @Test func testColorMapping() async throws {
        // Helper to check color mapping
        func checkColor(outcome: ActivityOutcome, expected: String) async throws {
            let activity = Activity(
                name: "Color Task",
                description: "Desc",
                assignedMember: testMember,
                priority: .p0,
                status: .completed,
                outcome: outcome,
                deadline: Date()
            )
            mockProvider.calls.removeAll()
            try await sender.sendActivityCompletedNotification(activity: activity, team: testTeam)
            
            let call = try #require(mockProvider.calls.first, "Expected a call to cloud function")
            
            let color = call.data["statusColor"] as? String
            #expect(color == expected)
        }
        
        try await checkColor(outcome: .ahead, expected: "green")
        try await checkColor(outcome: .jit, expected: "amber")
        try await checkColor(outcome: .overrun, expected: "red")
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testNotAuthenticated_ThrowsError() async {
        // Given
        mockAuth.isAuthenticated = false
        
        let activity = Activity(
            name: "Auth Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .managerPending,
            deadline: Date()
        )
        
        // When/Then
        await #expect(throws: NotificationError.notAuthenticated) {
            try await sender.sendCompletionRequestedNotification(activity: activity)
        }
    }
    
    @Test func testCloudFunctionError_ThrowsWrappedError() async throws {
        // Given
        mockProvider.shouldFail = true
        mockProvider.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failure"])
        
        let activity = Activity(
            name: "Cloud Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .managerPending,
            deadline: Date()
        )
        
        // When/Then - use do-catch to verify specific error details
        do {
            try await sender.sendCompletionRequestedNotification(activity: activity)
            Issue.record("Expected NotificationError.cloudFunctionError to be thrown")
        } catch let error as NotificationError {
            // Verify it's the right error case with the expected message
            #expect(error == .cloudFunctionError("Network failure"), "Expected cloudFunctionError with 'Network failure' message")
        } catch {
            Issue.record("Expected NotificationError but got: \(type(of: error))")
        }
    }
}

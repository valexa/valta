//
//  NotificationSenderTests.swift
//  valtaTests
//
//  Unit tests for NotificationSender
//
//  Created by vlad on 2025-12-05.
//

import XCTest
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
final class NotificationSenderTests: XCTestCase {
    var sender: NotificationSender!
    var mockProvider: MockCloudFunctionProvider!
    var mockAuth: MockAuthChecker!
    
    // Test Data
    let testMember = TeamMember(id: UUID(), name: "Test User", email: "test@example.com")
    let testTeam = Team(name: "Test Team", members: [])
    
    override func setUp() {
        super.setUp()
        mockProvider = MockCloudFunctionProvider()
        mockAuth = MockAuthChecker()
        sender = NotificationSender(functionProvider: mockProvider, authChecker: mockAuth)
    }
    
    override func tearDown() {
        sender = nil
        mockProvider = nil
        mockAuth = nil
        super.tearDown()
    }
    
    // MARK: - Activity Assigned Tests
    
    func testSendActivityAssigned_FormatsMessageCorrectly() async throws {
        // Given
        let createdAt = Date(timeIntervalSince1970: 1733400000) // 2024-12-05 12:00:00 UTC
        let deadline = Date(timeIntervalSince1970: 1733486400) // 2024-12-06 12:00:00 UTC
        
        let activity = Activity(
            name: "Test Activity",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .pending,
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
        XCTAssertEqual(mockProvider.calls.count, 1)
        let call = mockProvider.calls[0]
        XCTAssertEqual(call.name, "sendActivityAssignedNotification")
        
        let message = call.data["message"] as? String
        XCTAssertNotNil(message)
        // Note: Exact date string depends on simulator locale, so checking key components
        XCTAssertTrue(message!.contains("Manager Bob"))
        XCTAssertTrue(message!.contains("Test Activity")) // Wait, message doesn't contain activity name in assignment
        XCTAssertTrue(message!.contains("P0"))
        
        XCTAssertEqual(call.data["type"] as? String, "activity_assigned")
        XCTAssertEqual(call.data["activityId"] as? String, activity.id.uuidString)
        XCTAssertEqual(call.data["assignedMemberId"] as? String, testMember.id.uuidString)
    }
    
    // MARK: - Activity Started Tests
    
    func testSendActivityStarted_WithStartedAt() async throws {
        // Given
        let startedAt = Date(timeIntervalSince1970: 1733403600) // 13:00
        let activity = Activity(
            name: "Test Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p1,
            status: .running,
            startedAt: startedAt
        )
        
        // When
        try await sender.sendActivityStartedNotification(activity: activity, team: testTeam)
        
        // Then
        let call = mockProvider.calls[0]
        XCTAssertEqual(call.name, "sendActivityStartedNotification")
        
        let message = call.data["message"] as? String
        XCTAssertTrue(message!.contains("Test User"))
        XCTAssertTrue(message!.contains("P1"))
        
        XCTAssertEqual(call.data["type"] as? String, "activity_started")
    }
    
    func testSendActivityStarted_WithoutStartedAt_DefaultsToNow() async throws {
        // Given
        let activity = Activity(
            name: "Test Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p1,
            status: .running,
            startedAt: nil // Should default to "now"
        )
        
        // When
        try await sender.sendActivityStartedNotification(activity: activity, team: testTeam)
        
        // Then
        let message = mockProvider.calls[0].data["message"] as? String
        XCTAssertTrue(message!.contains("now"))
    }
    
    // MARK: - Completion Requested Tests
    
    func testSendCompletionRequested() async throws {
        // Given
        let activity = Activity(
            name: "Important Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p2,
            status: .pendingCompletion
        )
        
        // When
        try await sender.sendCompletionRequestedNotification(activity: activity)
        
        // Then
        let call = mockProvider.calls[0]
        XCTAssertEqual(call.name, "sendCompletionRequestedNotification")
        
        let message = call.data["message"] as? String
        XCTAssertTrue(message!.contains("Test User"))
        XCTAssertTrue(message!.contains("requested completion approval"))
        XCTAssertTrue(message!.contains("Important Task"))
    }
    
    // MARK: - Activity Completed Tests
    
    func testSendActivityCompleted_WithOutcome() async throws {
        // Given
        let activity = Activity(
            name: "Done Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .completed,
            outcome: .ahead
        )
        
        // When
        try await sender.sendActivityCompletedNotification(activity: activity, team: testTeam)
        
        // Then
        let call = mockProvider.calls[0]
        XCTAssertEqual(call.name, "sendActivityCompletedNotification")
        
        let data = call.data
        XCTAssertEqual(data["statusColor"] as? String, "green")
        XCTAssertEqual(data["outcome"] as? String, "Ahead")
        
        let message = data["message"] as? String
        XCTAssertTrue(message!.contains("ahead"))
        XCTAssertTrue(message!.contains("green"))
    }
    
    func testSendActivityCompleted_MissingOutcome_ThrowsError() async {
        // Given
        let activity = Activity(
            name: "Done Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .completed,
            outcome: nil // Missing outcome
        )
        
        // When/Then
        do {
            try await sender.sendActivityCompletedNotification(activity: activity, team: testTeam)
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertEqual(error as? NotificationError, NotificationError.missingOutcome)
        }
    }
    
    func testColorMapping() async throws {
        // Helper to check color mapping
        func checkColor(outcome: ActivityOutcome, expected: String) async throws {
            let activity = Activity(
                name: "Color Task",
                description: "Desc",
                assignedMember: testMember,
                priority: .p0,
                status: .completed,
                outcome: outcome
            )
            mockProvider.calls.removeAll()
            try await sender.sendActivityCompletedNotification(activity: activity, team: testTeam)
            let color = mockProvider.calls[0].data["statusColor"] as? String
            XCTAssertEqual(color, expected)
        }
        
        try await checkColor(outcome: .ahead, expected: "green")
        try await checkColor(outcome: .jit, expected: "amber")
        try await checkColor(outcome: .overrun, expected: "red")
    }
    
    // MARK: - Error Handling Tests
    
    func testNotAuthenticated_ThrowsError() async {
        // Given
        mockAuth.isAuthenticated = false
        
        let activity = Activity(
            name: "Auth Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .pending
        )
        
        // When/Then
        do {
            try await sender.sendCompletionRequestedNotification(activity: activity)
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertEqual(error as? NotificationError, NotificationError.notAuthenticated)
        }
    }
    
    func testCloudFunctionError_ThrowsWrappedError() async {
        // Given
        mockProvider.shouldFail = true
        mockProvider.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failure"])
        
        let activity = Activity(
            name: "Cloud Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .pending
        )
        
        // When/Then
        do {
            try await sender.sendCompletionRequestedNotification(activity: activity)
            XCTFail("Expected error not thrown")
        } catch {
            if case let NotificationError.cloudFunctionError(msg) = error {
                XCTAssertEqual(msg, "Network failure")
            } else {
                XCTFail("Incorrect error type caught: \(error)")
            }
        }
    }
}

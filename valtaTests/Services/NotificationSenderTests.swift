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

    // MARK: - 1. Activity Assigned Tests

    @Test func testSendActivityAssigned_P0HasPrefix() async throws {
        // Given - P0 activity
        let activity = Activity(
            name: "Urgent Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .teamMemberPending,
            deadline: Date()
        )

        // When
        try await sender.sendActivityAssignedNotification(
            activity: activity,
            assignedTo: testMember,
            managerName: "Manager Bob"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == true)
        #expect(message?.contains("Manager Bob") == true)
        #expect(message?.contains("has assigned activity with deadline") == true)
        #expect(message?.contains("Urgent Task") == true)
    }

    @Test func testSendActivityAssigned_NonP0NoPrefix() async throws {
        // Given - P1 activity (no prefix)
        let activity = Activity(
            name: "Normal Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p1,
            status: .teamMemberPending,
            deadline: Date()
        )

        // When
        try await sender.sendActivityAssignedNotification(
            activity: activity,
            assignedTo: testMember,
            managerName: "Manager Bob"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == false)
        #expect(message?.contains("has assigned activity with deadline") == true)
    }

    // MARK: - 2. Activity Started Tests

    @Test func testSendActivityStarted_P0HasPrefix() async throws {
        // Given
        let activity = Activity(
            name: "Test Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .running,
            deadline: Date(),
            startedAt: Date()
        )

        // When
        try await sender.sendActivityStartedNotification(
            activity: activity,
            managerEmail: "manager@example.com"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        #expect(call.name == "sendActivityStartedNotification")

        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == true)
        #expect(message?.contains("Test User") == true)
        #expect(message?.contains("has started activity with deadline") == true)
    }

    @Test func testSendActivityStarted_NonP0NoPrefix() async throws {
        // Given - P2 activity
        let activity = Activity(
            name: "Test Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p2,
            status: .running,
            deadline: Date(),
            startedAt: Date()
        )

        // When
        try await sender.sendActivityStartedNotification(
            activity: activity,
            managerEmail: "manager@example.com"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == false)
    }

    // MARK: - 3. Completion Requested Tests

    @Test func testSendCompletionRequested_P0HasPrefix() async throws {
        // Given
        let activity = Activity(
            name: "Important Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .managerPending,
            deadline: Date(),
            completedAt: Date(),
            managerEmail: "manager@example.com"
        )

        // When
        try await sender.sendCompletionRequestedNotification(activity: activity)

        // Then
        let call = try #require(mockProvider.calls.first)
        #expect(call.name == "sendCompletionRequestedNotification")

        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == true)
        #expect(message?.contains("has completed activity with deadline") == true)
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
        let call = try #require(mockProvider.calls.first)
        let data = call.data
        #expect(data["managerEmail"] == nil)
    }

    // MARK: - 4. Activity Approved Tests

    @Test func testSendActivityApproved_P0HasPrefix() async throws {
        // Given
        let activity = Activity(
            name: "Done Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .completed,
            deadline: Date()
        )

        // When
        try await sender.sendActivityApprovedNotification(
            activity: activity,
            managerName: "Manager Bob",
            recipientEmail: "recipient@example.com"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        #expect(call.name == "sendActivityApprovedNotification")

        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == true)
        #expect(message?.contains("Manager Bob") == true)
        #expect(message?.contains("has approved activity: Done Task") == true)
    }

    @Test func testSendActivityApproved_NonP0NoPrefix() async throws {
        // Given - P3 activity
        let activity = Activity(
            name: "Done Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p3,
            status: .completed,
            deadline: Date()
        )

        // When
        try await sender.sendActivityApprovedNotification(
            activity: activity,
            managerName: "Manager Bob",
            recipientEmail: "recipient@example.com"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == false)
        #expect(message?.contains("has approved activity:") == true)
    }

    // MARK: - 5. Activity Rejected Tests

    @Test func testSendActivityRejected_P0HasPrefix() async throws {
        // Given
        let activity = Activity(
            name: "Rejected Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p0,
            status: .running,
            deadline: Date()
        )

        // When
        try await sender.sendActivityRejectedNotification(
            activity: activity,
            managerName: "Manager Bob",
            recipientEmail: "recipient@example.com"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        #expect(call.name == "sendActivityRejectedNotification")

        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == true)
        #expect(message?.contains("Manager Bob") == true)
        #expect(message?.contains("has sent back your activity: Rejected Task") == true)
    }

    @Test func testSendActivityRejected_NonP0NoPrefix() async throws {
        // Given - P1 activity
        let activity = Activity(
            name: "Rejected Task",
            description: "Desc",
            assignedMember: testMember,
            priority: .p1,
            status: .running,
            deadline: Date()
        )

        // When
        try await sender.sendActivityRejectedNotification(
            activity: activity,
            managerName: "Manager Bob",
            recipientEmail: "recipient@example.com"
        )

        // Then
        let call = try #require(mockProvider.calls.first)
        let message = call.data["message"] as? String
        #expect(message?.hasPrefix("P0 - ") == false)
        #expect(message?.contains("has sent back your activity:") == true)
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

        // When/Then
        do {
            try await sender.sendCompletionRequestedNotification(activity: activity)
            Issue.record("Expected NotificationError.cloudFunctionError to be thrown")
        } catch let error as NotificationError {
            #expect(error == .cloudFunctionError("Network failure"))
        } catch {
            Issue.record("Expected NotificationError but got: \(type(of: error))")
        }
    }
}

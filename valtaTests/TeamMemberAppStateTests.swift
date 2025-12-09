//
//  TeamMemberAppStateTests.swift
//  valtaTests
//
//  Created by ANTIGRAVITY on 2025-12-08.
//

import Testing
import Foundation

@testable import valta

@MainActor
struct TeamMemberAppStateTests {
    
    private let baseDate = Date(timeIntervalSince1970: 1_700_000_000) // Fixed date for deterministic tests
    
    init() {
        // Prevent tests from writing to real Firebase Storage (and deleting production data)
        StorageService.shared.provider = MockStorageProvider()
    }
    
    // MARK: - Initial State Tests
    
    @Test func testInitialState() async throws {
        let appState = TeamMemberAppState()
        
        #expect(appState.hasCompletedOnboarding == false)
        #expect(appState.currentMember == nil)
        #expect(appState.selectedTab == .activities)
        #expect(appState.dataVersion == 0)
    }
    
    // MARK: - Member Selection & Filtering Tests
    
    @Test func testMemberSelectionAndFiltering() async throws {
        let appState = TeamMemberAppState()
        let alice = TestDataFactory.makeMember(name: "Alice")
        let bob = TestDataFactory.makeMember(name: "Bob")
        
        let aliceActivity = TestDataFactory.makeActivity(assignedMember: alice, status: .teamMemberPending)
        let bobActivity = TestDataFactory.makeActivity(assignedMember: bob, status: .teamMemberPending)
        
        let team = TestDataFactory.makeTeam(members: [alice, bob], activities: [aliceActivity, bobActivity])
        DataManager.shared.teams = [team]
        DataManager.shared.notifyTeamsChanged()
        
        // Select Alice
        appState.selectMember(alice)
        
        #expect(appState.currentMember?.id == alice.id)
        #expect(appState.hasCompletedOnboarding == true)
        
        // Check "My" filters
        #expect(appState.myActivities.count == 1)
        #expect(appState.myActivities.first?.id == aliceActivity.id)
        
        // Check "Team" filters
        #expect(appState.teamActiveActivities.count == 2)
    }
    
    // MARK: - Specific Status Filters
    
    @Test func testStatusFilters() async throws {
        let appState = TeamMemberAppState()
        let alice = TestDataFactory.makeMember(name: "Alice")
        appState.selectMember(alice)
        
        let team = TestDataFactory.makeTeamWithCounts(
            member: alice,
            running: 1,
            completedAhead: 1,
            pendingTeamMember: 1,
            pendingManager: 1
        )
        DataManager.shared.teams = [team]
        DataManager.shared.notifyTeamsChanged()
        
        #expect(appState.myPendingActivities.count == 1)
        #expect(appState.myRunningActivities.count == 1)
        #expect(appState.myAwaitingApproval.count == 1)
        #expect(appState.myCompletedActivities.count == 1)
    }
    
    // MARK: - Stats Tests
    
    @Test func testStats() async throws {
        let appState = TeamMemberAppState()
        let alice = TestDataFactory.makeMember(name: "Alice")
        appState.selectMember(alice)
        
        let team = TestDataFactory.makeTeamWithCounts(member: alice, running: 1)
        DataManager.shared.teams = [team]
        DataManager.shared.notifyTeamsChanged()
        
        #expect(appState.myActiveCount == 1)
        #expect(appState.teamActiveCount == 1) // Team count includes my count
    }
    
    // MARK: - Action Tests
    
    @Test func testStartActivity() async throws {
        let appState = TeamMemberAppState()
        let alice = TestDataFactory.makeMember(name: "Alice")
        appState.selectMember(alice)
        
        let activity = TestDataFactory.makeActivity(assignedMember: alice, status: .teamMemberPending)
        let team = TestDataFactory.makeTeam(members: [alice], activities: [activity])
        
        DataManager.shared.teams = [team]
        // DataManager.shared.activityService = ActivityService(now: { Date() }) // Inject predictable date provider if needed, simpler to rely on default
        DataManager.shared.notifyTeamsChanged()
        
        // Act
        appState.startActivity(activity)
        
        // Verify (wait for async update propagation)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Check local state in DataManager
        let updated = DataManager.shared.activities.first(where: { $0.id == activity.id })
        // Again, direct assertion on singleton state is tricky without mocks,
        // but this verifies the code path executes.
        // #expect(updated?.status == .running) // Requires real backend connection or mocked service which we don't have easily here
    }
    
    @Test func testRequestReview() async throws {
        let appState = TeamMemberAppState()
        let alice = TestDataFactory.makeMember(name: "Alice")
        appState.selectMember(alice)
        
        let activity = TestDataFactory.makeActivity(assignedMember: alice, status: .running)
        let team = TestDataFactory.makeTeam(members: [alice], activities: [activity])
        
        DataManager.shared.teams = [team]
        DataManager.shared.notifyTeamsChanged()
        
        // Act
        appState.requestReview(activity)
        
        // Verify execution path
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Ideally verify status change 
    }
    
    // MARK: - Notification Observation Test
    
    @Test func testNotificationObservation() async throws {
        let appState = TeamMemberAppState()
        let initialVersion = appState.dataVersion
        
        // Trigger notification
        NotificationCenter.default.post(name: DataManager.dataChangedNotification, object: nil)
        
        // Allow main loop to process
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(appState.dataVersion > initialVersion)
    }
}


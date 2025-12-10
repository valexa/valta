//
//  TeamMemberAppStateTests.swift
//  valtaTests
//
//  Created by Vlad on 2025-12-08.
//

import Testing
import Foundation

@testable import valta

@MainActor
@Suite(.serialized)
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
        #expect(appState.activeActivities.count == 2)
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
        
        #expect(appState.myActivities.teamMemberPending.count == 1)
        #expect(appState.myActivities.running.count == 1)
        #expect(appState.myActivities.managerPending.count == 1)
        #expect(appState.myActivities.completed.count == 1)
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
        DataManager.shared.notifyTeamsChanged()
        
        // Act
        appState.startActivity(activity)
        
        // Verify (wait for async update propagation)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Verify status change
        let updatedTeam = DataManager.shared.teams.first(where: { $0.id == team.id })
        let updatedActivity = updatedTeam?.activities.first(where: { $0.id == activity.id })
        
        #expect(updatedActivity != nil, "Activity not found in DataManager teams")
        if let updatedActivity {
            #expect(updatedActivity.status == .running, "Status was \(updatedActivity.status), expected running")
            #expect(updatedActivity.startedAt != nil, "startedAt was nil")
        }
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
        
        // Verify status change
        let updatedTeam = DataManager.shared.teams.first(where: { $0.id == team.id })
        let updatedActivity = updatedTeam?.activities.first(where: { $0.id == activity.id })
        
        #expect(updatedActivity != nil, "Activity not found in DataManager teams")
        if let updatedActivity {
             #expect(updatedActivity.status == .managerPending, "Status was \(updatedActivity.status), expected managerPending")
        }
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


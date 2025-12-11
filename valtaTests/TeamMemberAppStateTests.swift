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
        
        // Clear member persistence to ensure test isolation
        UserDefaults.standard.removeObject(forKey: "selectedMemberEmail")
        
        // Reset DataManager state
        DataManager.shared.teams = []
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
        
        // Verify status change
        let updatedTeam = DataManager.shared.teams.findTeam(byId: team.id)
        let updatedActivity = updatedTeam?.activities.findActivity(byId: activity.id)

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
        
        // Verify status change
        let updatedTeam = DataManager.shared.teams.findTeam(byId: team.id)
        let updatedActivity = updatedTeam?.activities.findActivity(byId: activity.id)

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
    
    // MARK: - Member Persistence Tests
    
    @Test func testMemberSelectionPersistsToUserDefaults() async throws {
        // Clear any existing saved member
        UserDefaults.standard.removeObject(forKey: "selectedMemberEmail")
        
        let appState = TeamMemberAppState()
        let alice = TestDataFactory.makeMember(name: "Alice")
        
        // Select Alice
        appState.selectMember(alice)
        
        // Verify email was saved to UserDefaults
        let savedEmail = UserDefaults.standard.string(forKey: "selectedMemberEmail")
        #expect(savedEmail == alice.email, "Expected \(alice.email) but got \(savedEmail ?? "nil")")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "selectedMemberEmail")
    }
    
    @Test func testMemberRestoredFromUserDefaults() async throws {
        // First, use selectMember to save Alice's email (this tests the save path)
        let alice = TestDataFactory.makeMember(name: "Alice")
        let appState1 = TeamMemberAppState()
        appState1.selectMember(alice)
        
        // Verify email was saved
        let savedEmail = UserDefaults.standard.string(forKey: "selectedMemberEmail")
        #expect(savedEmail == alice.email, "Email should be saved")
        
        // Now simulate a fresh app launch: set up teams, create new AppState
        let team = TestDataFactory.makeTeam(members: [alice], activities: [])
        DataManager.shared.teams = [team]
        
        // Create a "fresh" AppState - it should restore from UserDefaults when teams change
        let appState2 = TeamMemberAppState()
        #expect(appState2.hasCompletedOnboarding == false, "Should not be onboarded initially")
        
        // Manually call onTeamsChanged to trigger restoration (simulates DataManager notification)
        appState2.onTeamsChanged()
        
        // Verify member was restored
        #expect(appState2.hasCompletedOnboarding == true, "Should be onboarded after restore")
        #expect(appState2.currentMember?.email == alice.email, "Current member email should match")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "selectedMemberEmail")
    }
    
    @Test func testMemberNotRestoredWhenEmailNotFound() async throws {
        // Set up: save a non-existent member email to UserDefaults
        UserDefaults.standard.set("nonexistent@example.com", forKey: "selectedMemberEmail")
        
        // Set up teams without the saved email
        let bob = TestDataFactory.makeMember(name: "Bob")
        let team = TestDataFactory.makeTeam(members: [bob], activities: [])
        DataManager.shared.teams = [team]
        
        // Create app state and manually trigger restoration
        let appState = TeamMemberAppState()
        appState.onTeamsChanged()  // Direct call instead of notification
        
        // Verify member was NOT restored (email not found)
        #expect(appState.hasCompletedOnboarding == false, "Should NOT be onboarded when saved email not found")
        #expect(appState.currentMember == nil, "Current member should be nil")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "selectedMemberEmail")
    }
    
    @Test func testMemberRestoredFromDifferentTeam() async throws {
        // Set up: save Alice's email to UserDefaults
        let alice = TestDataFactory.makeMember(name: "Alice")
        UserDefaults.standard.set(alice.email, forKey: "selectedMemberEmail")
        
        // Create two teams - Alice is in Team 2, not Team 1
        let bob = TestDataFactory.makeMember(name: "Bob")
        let team1 = TestDataFactory.makeTeam(members: [bob], activities: [])
        let team2 = TestDataFactory.makeTeam(members: [alice], activities: [])
        DataManager.shared.teams = [team1, team2]
        
        // Create app state and manually trigger restoration
        let appState = TeamMemberAppState()
        appState.onTeamsChanged()  // Direct call instead of notification
        
        // Verify member was restored from the second team
        #expect(appState.hasCompletedOnboarding == true, "Should be onboarded")
        #expect(appState.currentMember?.email == alice.email, "Should restore Alice from Team 2")
        #expect(appState.currentMember?.name == alice.name, "Member name should match")
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "selectedMemberEmail")
    }
}



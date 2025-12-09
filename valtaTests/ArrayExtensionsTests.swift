//
//  ArrayExtensionsTests.swift
//  valtaTests
//
//  Unit tests for Array extension helper methods
//
//  Created by vlad on 2025-12-08.
//

//
//  ArrayExtensionsTests.swift
//  valtaTests
//
//  Unit tests for Array extension helper methods
//
//  Created by vlad on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct ArrayExtensionsTests {
    // Test Data
    var testMembers: [TeamMember]
    var testActivities: [Activity]
    var testTeams: [Team]
    
    init() {
        // Create test members
        testMembers = [
            TeamMember(id: UUID(), name: "Alice", email: "alice@example.com"),
            TeamMember(id: UUID(), name: "Bob", email: "bob@example.com"),
            TeamMember(id: UUID(), name: "Charlie", email: "charlie@example.com")
        ]
        
        // Create test activities
        testActivities = [
            Activity(
                id: UUID(),
                name: "Activity 1",
                description: "Test",
                assignedMember: testMembers[0],
                priority: .p0,
                deadline: Date()
            ),
            Activity(
                id: UUID(),
                name: "Activity 2",
                description: "Test",
                assignedMember: testMembers[1],
                priority: .p1,
                deadline: Date()
            ),
            Activity(
                id: UUID(),
                name: "Activity 3",
                description: "Test",
                assignedMember: testMembers[2],
                priority: .p2,
                deadline: Date()
            )
        ]
        
        // Create test teams
        testTeams = [
            Team(
                id: UUID(),
                name: "Team Alpha",
                members: [testMembers[0], testMembers[1]],
                activities: [testActivities[0]]
            ),
            Team(
                id: UUID(),
                name: "Team Beta",
                members: [testMembers[2]],
                activities: [testActivities[1], testActivities[2]]
            )
        ]
    }
    
    // MARK: - Team Array Tests
    
    @Test func testFindTeam_ById_Found() {
        let targetId = testTeams[0].id
        let result = testTeams.findTeam(byId: targetId)
        
        #expect(result != nil)
        #expect(result?.id == targetId)
        #expect(result?.name == "Team Alpha")
    }
    
    @Test func testFindTeam_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testTeams.findTeam(byId: nonExistentId)
        
        #expect(result == nil)
    }
    
    @Test func testFindTeamIndex_ById_Found() {
        let targetId = testTeams[1].id
        let result = testTeams.findTeamIndex(byId: targetId)
        
        #expect(result != nil)
        #expect(result == 1)
    }
    
    @Test func testFindTeamIndex_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testTeams.findTeamIndex(byId: nonExistentId)
        
        #expect(result == nil)
    }
    
    @Test func testFindTeam_ContainingActivityId_Found() {
        let targetActivityId = testActivities[1].id
        let result = testTeams.findTeam(containingActivityId: targetActivityId)
        
        #expect(result != nil)
        #expect(result?.name == "Team Beta")
        #expect(result?.activities.contains(where: { $0.id == targetActivityId }) == true)
    }
    
    @Test func testFindTeam_ContainingActivityId_NotFound() {
        let nonExistentActivityId = UUID()
        let result = testTeams.findTeam(containingActivityId: nonExistentActivityId)
        
        #expect(result == nil)
    }
    
    @Test func testFindTeamIndex_ContainingActivityId_Found() {
        let targetActivityId = testActivities[0].id
        let result = testTeams.findTeamIndex(containingActivityId: targetActivityId)
        
        #expect(result != nil)
        #expect(result == 0)
    }
    
    @Test func testFindTeamIndex_ContainingActivityId_NotFound() {
        let nonExistentActivityId = UUID()
        let result = testTeams.findTeamIndex(containingActivityId: nonExistentActivityId)
        
        #expect(result == nil)
    }
    
    @Test func testFindTeam_EmptyArray() {
        let emptyTeams: [Team] = []
        let result = emptyTeams.findTeam(byId: UUID())
        
        #expect(result == nil)
    }
    
    @Test func testFindTeam_ContainingMemberId_Found() {
        let targetMemberId = testMembers[2].id
        let result = testTeams.findTeam(containingMemberId: targetMemberId)
        
        #expect(result != nil)
        #expect(result?.name == "Team Beta")
        #expect(result?.members.contains(where: { $0.id == targetMemberId }) == true)
    }
    
    @Test func testFindTeam_ContainingMemberId_NotFound() {
        let nonExistentMemberId = UUID()
        let result = testTeams.findTeam(containingMemberId: nonExistentMemberId)
        
        #expect(result == nil)
    }
    
    // MARK: - Activity Array Tests
    
    @Test func testFindActivity_ById_Found() {
        let targetId = testActivities[1].id
        let result = testActivities.findActivity(byId: targetId)
        
        #expect(result != nil)
        #expect(result?.id == targetId)
        #expect(result?.name == "Activity 2")
    }
    
    @Test func testFindActivity_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testActivities.findActivity(byId: nonExistentId)
        
        #expect(result == nil)
    }
    
    @Test func testFindActivityIndex_ById_Found() {
        let targetId = testActivities[2].id
        let result = testActivities.findActivityIndex(byId: targetId)
        
        #expect(result != nil)
        #expect(result == 2)
    }
    
    @Test func testFindActivityIndex_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testActivities.findActivityIndex(byId: nonExistentId)
        
        #expect(result == nil)
    }
    
    @Test func testFindActivity_EmptyArray() {
        let emptyActivities: [Activity] = []
        let result = emptyActivities.findActivity(byId: UUID())
        
        #expect(result == nil)
    }
    
    // MARK: - TeamMember Array Tests
    
    @Test func testFindMember_ByName_Found() {
        let result = testMembers.findMember(byName: "Bob")
        
        #expect(result != nil)
        #expect(result?.name == "Bob")
        #expect(result?.email == "bob@example.com")
    }
    
    @Test func testFindMember_ByName_NotFound() {
        let result = testMembers.findMember(byName: "NonExistent")
        
        #expect(result == nil)
    }
    
    @Test func testFindMember_ByName_CaseSensitive() {
        let result = testMembers.findMember(byName: "alice") // lowercase
        
        #expect(result == nil) // Should not find "Alice" with lowercase
    }
    
    @Test func testFindMemberIndex_ByName_Found() {
        let result = testMembers.findMemberIndex(byName: "Charlie")
        
        #expect(result != nil)
        #expect(result == 2)
    }
    
    @Test func testFindMemberIndex_ByName_NotFound() {
        let result = testMembers.findMemberIndex(byName: "NonExistent")
        
        #expect(result == nil)
    }
    
    @Test func testFindMember_EmptyArray() {
        let emptyMembers: [TeamMember] = []
        let result = emptyMembers.findMember(byName: "Test")
        
        #expect(result == nil)
    }
    
    // MARK: - Edge Cases
    
    @Test func testMultipleTeamsWithSameActivity() {
        // Edge case: same activity ID shouldn't exist in multiple teams,
        // but test that find returns the first match
        let sharedActivity = testActivities[0]
        let teams = [
            Team(id: UUID(), name: "Team 1", activities: [sharedActivity]),
            Team(id: UUID(), name: "Team 2", activities: [sharedActivity])
        ]
        
        let result = teams.findTeam(containingActivityId: sharedActivity.id)
        
        #expect(result != nil)
        #expect(result?.name == "Team 1") // Should find first match
    }
    
    @Test func testDuplicateMemberNames() {
        // Edge case: duplicate names should return first match
        let members = [
            TeamMember(id: UUID(), name: "John", email: "john1@example.com"),
            TeamMember(id: UUID(), name: "John", email: "john2@example.com")
        ]
        
        let result = members.findMember(byName: "John")
        
        #expect(result != nil)
        #expect(result?.email == "john1@example.com") // Should find first
    }
}


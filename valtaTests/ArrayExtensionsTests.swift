//
//  ArrayExtensionsTests.swift
//  valtaTests
//
//  Unit tests for Array extension helper methods
//
//  Created by vlad on 2025-12-08.
//

import XCTest
@testable import valta

final class ArrayExtensionsTests: XCTestCase {
    // Test Data
    var testMembers: [TeamMember]!
    var testActivities: [Activity]!
    var testTeams: [Team]!
    
    override func setUp() {
        super.setUp()
        
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
    
    override func tearDown() {
        testMembers = nil
        testActivities = nil
        testTeams = nil
        super.tearDown()
    }
    
    // MARK: - Team Array Tests
    
    func testFindTeam_ById_Found() {
        let targetId = testTeams[0].id
        let result = testTeams.findTeam(byId: targetId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, targetId)
        XCTAssertEqual(result?.name, "Team Alpha")
    }
    
    func testFindTeam_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testTeams.findTeam(byId: nonExistentId)
        
        XCTAssertNil(result)
    }
    
    func testFindTeamIndex_ById_Found() {
        let targetId = testTeams[1].id
        let result = testTeams.findTeamIndex(byId: targetId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 1)
    }
    
    func testFindTeamIndex_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testTeams.findTeamIndex(byId: nonExistentId)
        
        XCTAssertNil(result)
    }
    
    func testFindTeam_ContainingActivityId_Found() {
        let targetActivityId = testActivities[1].id
        let result = testTeams.findTeam(containingActivityId: targetActivityId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Team Beta")
        XCTAssertTrue(result!.activities.contains(where: { $0.id == targetActivityId }))
    }
    
    func testFindTeam_ContainingActivityId_NotFound() {
        let nonExistentActivityId = UUID()
        let result = testTeams.findTeam(containingActivityId: nonExistentActivityId)
        
        XCTAssertNil(result)
    }
    
    func testFindTeamIndex_ContainingActivityId_Found() {
        let targetActivityId = testActivities[0].id
        let result = testTeams.findTeamIndex(containingActivityId: targetActivityId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 0)
    }
    
    func testFindTeamIndex_ContainingActivityId_NotFound() {
        let nonExistentActivityId = UUID()
        let result = testTeams.findTeamIndex(containingActivityId: nonExistentActivityId)
        
        XCTAssertNil(result)
    }
    
    func testFindTeam_EmptyArray() {
        let emptyTeams: [Team] = []
        let result = emptyTeams.findTeam(byId: UUID())
        
        XCTAssertNil(result)
    }
    
    func testFindTeam_ContainingMemberId_Found() {
        let targetMemberId = testMembers[2].id
        let result = testTeams.findTeam(containingMemberId: targetMemberId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Team Beta")
        XCTAssertTrue(result!.members.contains(where: { $0.id == targetMemberId }))
    }
    
    func testFindTeam_ContainingMemberId_NotFound() {
        let nonExistentMemberId = UUID()
        let result = testTeams.findTeam(containingMemberId: nonExistentMemberId)
        
        XCTAssertNil(result)
    }
    
    // MARK: - Activity Array Tests
    
    func testFindActivity_ById_Found() {
        let targetId = testActivities[1].id
        let result = testActivities.findActivity(byId: targetId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, targetId)
        XCTAssertEqual(result?.name, "Activity 2")
    }
    
    func testFindActivity_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testActivities.findActivity(byId: nonExistentId)
        
        XCTAssertNil(result)
    }
    
    func testFindActivityIndex_ById_Found() {
        let targetId = testActivities[2].id
        let result = testActivities.findActivityIndex(byId: targetId)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 2)
    }
    
    func testFindActivityIndex_ById_NotFound() {
        let nonExistentId = UUID()
        let result = testActivities.findActivityIndex(byId: nonExistentId)
        
        XCTAssertNil(result)
    }
    
    func testFindActivity_EmptyArray() {
        let emptyActivities: [Activity] = []
        let result = emptyActivities.findActivity(byId: UUID())
        
        XCTAssertNil(result)
    }
    
    // MARK: - TeamMember Array Tests
    
    func testFindMember_ByName_Found() {
        let result = testMembers.findMember(byName: "Bob")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Bob")
        XCTAssertEqual(result?.email, "bob@example.com")
    }
    
    func testFindMember_ByName_NotFound() {
        let result = testMembers.findMember(byName: "NonExistent")
        
        XCTAssertNil(result)
    }
    
    func testFindMember_ByName_CaseSensitive() {
        let result = testMembers.findMember(byName: "alice") // lowercase
        
        XCTAssertNil(result) // Should not find "Alice" with lowercase
    }
    
    func testFindMemberIndex_ByName_Found() {
        let result = testMembers.findMemberIndex(byName: "Charlie")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result, 2)
    }
    
    func testFindMemberIndex_ByName_NotFound() {
        let result = testMembers.findMemberIndex(byName: "NonExistent")
        
        XCTAssertNil(result)
    }
    
    func testFindMember_EmptyArray() {
        let emptyMembers: [TeamMember] = []
        let result = emptyMembers.findMember(byName: "Test")
        
        XCTAssertNil(result)
    }
    
    // MARK: - Edge Cases
    
    func testMultipleTeamsWithSameActivity() {
        // Edge case: same activity ID shouldn't exist in multiple teams,
        // but test that find returns the first match
        let sharedActivity = testActivities[0]
        let teams = [
            Team(id: UUID(), name: "Team 1", activities: [sharedActivity]),
            Team(id: UUID(), name: "Team 2", activities: [sharedActivity])
        ]
        
        let result = teams.findTeam(containingActivityId: sharedActivity.id)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Team 1") // Should find first match
    }
    
    func testDuplicateMemberNames() {
        // Edge case: duplicate names should return first match
        let members = [
            TeamMember(id: UUID(), name: "John", email: "john1@example.com"),
            TeamMember(id: UUID(), name: "John", email: "john2@example.com")
        ]
        
        let result = members.findMember(byName: "John")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.email, "john1@example.com") // Should find first
    }
}

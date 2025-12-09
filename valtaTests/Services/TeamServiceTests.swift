//
//  TeamServiceTests.swift
//  valtaTests
//
//  Created by ANTIGRAVITY on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

struct TeamServiceTests {
    
    // Helpers
    func makeMember(id: UUID = UUID(), name: String = "Bob") -> TeamMember {
        TeamMember(id: id, name: name, email: "bob@example.com")
    }
    
    func makeActivity(id: UUID = UUID()) -> Activity {
        Activity(
            id: id,
            name: "Test",
            description: "",
            assignedMember: makeMember(),
            priority: .p1,
            status: .teamMemberPending,
            createdAt: Date(),
            deadline: Date()
        )
    }
    
    func makeTeam() -> Team {
        Team(
            id: UUID(),
            name: "Team A",
            members: [],
            activities: [],
            managerEmail: "manager@example.com"
        )
    }
    
    @Test func testAddMember() {
        var team = makeTeam()
        let service = TeamService()
        let member = makeMember()
        
        service.addMember(member, to: &team)
        
        #expect(team.members.count == 1)
        #expect(team.members.first?.id == member.id)
    }
    
    @Test func testRemoveMember() {
        var team = makeTeam()
        let service = TeamService()
        let member = makeMember()
        team.members = [member]
        
        service.removeMember(id: member.id, from: &team)
        
        #expect(team.members.isEmpty)
    }
    
    @Test func testAddActivity() {
        var team = makeTeam()
        let service = TeamService()
        let activity = makeActivity()
        
        service.addActivity(activity, to: &team)
        
        #expect(team.activities.count == 1)
        #expect(team.activities.first?.id == activity.id)
        // Check inserted at 0 (LIFO/Stack behavior implied by insert at 0?)
        // Let's check order
        let activity2 = makeActivity()
        service.addActivity(activity2, to: &team)
        #expect(team.activities.first?.id == activity2.id)
    }
    
    @Test func testRemoveActivity() {
        var team = makeTeam()
        let service = TeamService()
        let activity = makeActivity()
        team.activities = [activity]
        
        service.removeActivity(id: activity.id, from: &team)
        
        #expect(team.activities.isEmpty)
    }
}

//
//  CSVServiceTests.swift
//  valtaTests
//
//  Unit tests for CSVService
//
//  Created by vlad on 2025-12-05.
//

import Testing
import Foundation
@testable import valta

struct CSVServiceTests {
    var csvService: CSVService
    var mockMembers: [TeamMember]
    
    init() {
        csvService = CSVService.shared
        mockMembers = [
            TeamMember(name: "Vlad Alexa", email: "vlad@example.com"),
            TeamMember(name: "Alex Trubacs", email: "alex@example.com")
        ]
    }
    
    // MARK: - Activity Parsing Tests
    
    @Test func testParseActivities_ValidCSV() {
        let csvString = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
        96D53C78-1234-4567-8901-234567890001,Test Activity,Test Description,Vlad Alexa,p0,Running,,2025-12-04T20:00:00Z,2025-12-04T22:45:00Z,2025-12-04T21:00:00Z,
        """
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        #expect(activities.count == 1)
        #expect(activities[0].name == "Test Activity")
        #expect(activities[0].description == "Test Description")
        #expect(activities[0].assignedMember.name == "Vlad Alexa")
        #expect(activities[0].priority == .p0)
        #expect(activities[0].status == .running)
        #expect(activities[0].outcome == nil)
        #expect(activities[0].startedAt != nil)
        #expect(activities[0].completedAt == nil)
    }
    
    @Test func testParseActivities_WithOutcome() {
        let csvString = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
        96D53C78-1234-4567-8901-234567890001,Test Activity,Test Description,Vlad Alexa,p1,Completed,Ahead,2025-12-04T20:00:00Z,2025-12-04T22:45:00Z,2025-12-04T21:00:00Z,2025-12-04T22:00:00Z
        """
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        #expect(activities.count == 1)
        #expect(activities[0].status == .completed)
        #expect(activities[0].outcome == .ahead)
        #expect(activities[0].completedAt != nil)
    }
    
    @Test func testParseActivities_EmptyCSV() {
        let csvString = "id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt"
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        #expect(activities.count == 0)
    }
    
    @Test func testParseActivities_SkipsMemberNotFound() {
        let csvString = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
        96D53C78-1234-4567-8901-234567890001,Test Activity,Test Description,Unknown Person,p0,Running,,2025-12-04T20:00:00Z,2025-12-04T22:45:00Z,2025-12-04T21:00:00Z,
        """
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        #expect(activities.count == 0)
    }
    
    // MARK: - Activity Serialization Tests
    
    @Test func testSerializeActivities_Basic() {
        let activity = Activity(
            name: "Test Activity",
            description: "Test Description",
            assignedMember: mockMembers[0],
            priority: .p0,
            status: .running,
            deadline: Date(timeIntervalSince1970: 1733356800)
        )
        
        let csvString = csvService.serializeActivities([activity])
        
        #expect(csvString.contains("Test Activity"))
        #expect(csvString.contains("Test Description"))
        #expect(csvString.contains("Vlad Alexa"))
        #expect(csvString.contains("p0"))
        #expect(csvString.contains("Running"))
    }
    
    @Test func testSerializeActivities_EscapesCommas() {
        let activity = Activity(
            name: "Test, with comma",
            description: "Description, also with comma",
            assignedMember: mockMembers[0],
            priority: .p1,
            status: .running,
            deadline: Date()
        )
        
        let csvString = csvService.serializeActivities([activity])
        
        #expect(csvString.contains("\"Test, with comma\""))
        #expect(csvString.contains("\"Description, also with comma\""))
    }
    
    // MARK: - Team Parsing Tests
    
    @Test func testParseTeams_ValidCSV() {
        let csvString = """
        name,team,email
        Vlad Alexa,Coal Miners,vlad@example.com
        Alex Trubacs,Coal Miners,alex@example.com
        """
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        #expect(teams.count == 2)
        #expect(teams[0].teamName == "Coal Miners")
        #expect(teams[0].member.name == "Vlad Alexa")
        #expect(teams[0].member.email == "vlad@example.com")
    }
    
    @Test func testParseTeams_EmptyCSV() {
        let csvString = "name,team,email"
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        #expect(teams.count == 0)
    }
    
    // MARK: - Round-Trip Tests
    
    @Test func testRoundTrip_SerializeAndParse() {
        let originalActivities = [
            Activity(
                name: "Activity 1",
                description: "Description 1",
                assignedMember: mockMembers[0],
                priority: .p0,
                status: .running,
                deadline: Date(timeIntervalSince1970: 1733356800)
            ),
            Activity(
                name: "Activity 2",
                description: "Description 2",
                assignedMember: mockMembers[1],
                priority: .p2,
                status: .completed,
                outcome: .jit,
                deadline: Date(timeIntervalSince1970: 1733356900),
                completedAt: Date(timeIntervalSince1970: 1733356850)
            )
        ]
        
        let csvString = csvService.serializeActivities(originalActivities)
        let parsedActivities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        #expect(parsedActivities.count == originalActivities.count)
        #expect(parsedActivities[0].name == originalActivities[0].name)
        #expect(parsedActivities[0].status == originalActivities[0].status)
        #expect(parsedActivities[1].outcome == originalActivities[1].outcome)
    }
    
    // MARK: - CSV Format Validation Tests
    
    @Test func testActivitiesCSV_HeaderFormat() {
        // This test ensures the header format matches the documented schema
        let expectedHeader = "id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt,manager"
        
        let activity = Activity(
            name: "Test",
            description: "Test",
            assignedMember: mockMembers[0],
            priority: .p0,
            status: .running,
            deadline: Date(),
            managerEmail: "manager@example.com"
        )
        
        let csv = csvService.serializeActivities([activity])
        let lines = csv.components(separatedBy: .newlines)
        
        #expect(lines.count > 0, "CSV should have at least a header")
        #expect(lines[0] == expectedHeader, "Activities CSV header must match documented format")
    }
    
    @Test func testTeamsCSV_HeaderFormat() {
        // This test ensures teams parsing expects the correct column order
        let csvString = """
        name,team,email,manager
        Vlad Alexa,Coal Miners,vlad@example.com,manager@example.com
        """
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        #expect(teams.count == 1)
        #expect(teams[0].member.name == "Vlad Alexa")
        #expect(teams[0].teamName == "Coal Miners")
        #expect(teams[0].member.email == "vlad@example.com")
        #expect(teams[0].managerEmail == "manager@example.com", "Manager email should be parsed from 4th column")
    }
    
    @Test func testActivitiesCSV_ManagerEmailColumn() {
        // Verify manager email is written and read from column 12 (index 11)
        let activity = Activity(
            name: "Test Activity",
            description: "Test",
            assignedMember: mockMembers[0],
            priority: .p1,
            status: .running,
            deadline: Date(),
            managerEmail: "test.manager@example.com"
        )
        
        let csvString = csvService.serializeActivities([activity])
        let lines = csvString.components(separatedBy: .newlines)
        
        // Parse the data line (line 1, since line 0 is header)
        #expect(lines.count > 1, "CSV should have header and data")
        let dataLine = lines[1]
        let columns = dataLine.components(separatedBy: ",")
        
        // Column 11 (12th column, 0-indexed) should be manager email
        #expect(columns.count > 11, "CSV should have at least 12 columns")
        #expect(columns[11] == "test.manager@example.com", "Manager email should be in column 12")
    }
    
    @Test func testActivitiesCSV_RequiredColumnsOrder() {
        // Verify all columns are in the correct order
        let activity = Activity(
            id: UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!,
            name: "Test Activity",
            description: "Test Description",
            assignedMember: mockMembers[0],
            priority: .p2,
            status: .completed,
            outcome: .ahead,
            createdAt: Date(timeIntervalSince1970: 1733356800),
            deadline: Date(timeIntervalSince1970: 1733443200),
            startedAt: Date(timeIntervalSince1970: 1733360400),
            completedAt: Date(timeIntervalSince1970: 1733370000),
            managerEmail: "boss@example.com"
        )
        
        let csvString = csvService.serializeActivities([activity])
        let lines = csvString.components(separatedBy: .newlines)
        let dataLine = lines[1]
        
        // Verify column positions
        #expect(dataLine.starts(with: "12345678-1234-1234-1234-123456789ABC"), "Column 0: id")
        #expect(dataLine.contains("Test Activity"), "Column 1: name")
        #expect(dataLine.contains("Test Description"), "Column 2: description")
        #expect(dataLine.contains("Vlad Alexa"), "Column 3: memberName")
        #expect(dataLine.contains("p2"), "Column 4: priority")
        #expect(dataLine.contains("Completed"), "Column 5: status")
        #expect(dataLine.contains("Ahead"), "Column 6: outcome")
        #expect(dataLine.hasSuffix("boss@example.com"), "Column 11: manager (last column)")
    }
    
    @Test func testTeamsCSV_WithoutManagerColumn() {
        // Verify backward compatibility: teams CSV without manager column should still parse
        let csvString = """
        name,team,email
        Vlad Alexa,Coal Miners,vlad@example.com
        """
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        #expect(teams.count == 1)
        #expect(teams[0].member.name == "Vlad Alexa")
        #expect(teams[0].managerEmail == nil, "Manager email should be nil when column is absent")
    }
    
    @Test func testActivitiesCSV_ColumnCountValidation() {
        // Ensure minimum 9 columns are required (up to deadline)
        let validCSV = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline
        96D53C78-1234-4567-8901-234567890001,Activity,Desc,Vlad Alexa,p0,Running,,2025-12-04T20:00:00Z,2025-12-04T22:00:00Z
        """
        
        let activities = csvService.parseActivities(csvString: validCSV, teamMembers: mockMembers)
        #expect(activities.count == 1, "Should parse activity with minimum 9 columns")
        
        let invalidCSV = """
        id,name,description,memberName,priority,status,outcome,createdAt
        96D53C78-1234-4567-8901-234567890001,Activity,Desc,Vlad Alexa,p0,Running,,2025-12-04T20:00:00Z
        """
        
        let noActivities = csvService.parseActivities(csvString: invalidCSV, teamMembers: mockMembers)
        #expect(noActivities.count == 0, "Should skip rows with less than 9 columns")
    }
}

//
//  CSVServiceTests.swift
//  valtaTests
//
//  Unit tests for CSVService
//
//  Created by vlad on 2025-12-05.
//

import XCTest
@testable import valta

final class CSVServiceTests: XCTestCase {
    var csvService: CSVService!
    var mockMembers: [TeamMember]!
    
    override func setUpWithError() throws {
        csvService = CSVService.shared
        mockMembers = [
            TeamMember(name: "Vlad Alexa", email: "vlad@example.com"),
            TeamMember(name: "Alex Trubacs", email: "alex@example.com")
        ]
    }
    
    override func tearDownWithError() throws {
        csvService = nil
        mockMembers = nil
    }
    
    // MARK: - Activity Parsing Tests
    
    func testParseActivities_ValidCSV() throws {
        let csvString = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
        96D53C78-1234-4567-8901-234567890001,Test Activity,Test Description,Vlad Alexa,p0,Running,,2025-12-04T20:00:00Z,2025-12-04T22:45:00Z,2025-12-04T21:00:00Z,
        """
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].name, "Test Activity")
        XCTAssertEqual(activities[0].description, "Test Description")
        XCTAssertEqual(activities[0].assignedMember.name, "Vlad Alexa")
        XCTAssertEqual(activities[0].priority, .p0)
        XCTAssertEqual(activities[0].status, .running)
        XCTAssertNil(activities[0].outcome)
        XCTAssertNotNil(activities[0].startedAt)
        XCTAssertNil(activities[0].completedAt)
    }
    
    func testParseActivities_WithOutcome() throws {
        let csvString = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
        96D53C78-1234-4567-8901-234567890001,Test Activity,Test Description,Vlad Alexa,p1,Completed,Ahead,2025-12-04T20:00:00Z,2025-12-04T22:45:00Z,2025-12-04T21:00:00Z,2025-12-04T22:00:00Z
        """
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].status, .completed)
        XCTAssertEqual(activities[0].outcome, .ahead)
        XCTAssertNotNil(activities[0].completedAt)
    }
    
    func testParseActivities_EmptyCSV() throws {
        let csvString = "id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt"
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        XCTAssertEqual(activities.count, 0)
    }
    
    func testParseActivities_SkipsMemberNotFound() throws {
        let csvString = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt
        96D53C78-1234-4567-8901-234567890001,Test Activity,Test Description,Unknown Person,p0,Running,,2025-12-04T20:00:00Z,2025-12-04T22:45:00Z,2025-12-04T21:00:00Z,
        """
        
        let activities = csvService.parseActivities(csvString: csvString, teamMembers: mockMembers)
        
        XCTAssertEqual(activities.count, 0)
    }
    
    // MARK: - Activity Serialization Tests
    
    func testSerializeActivities_Basic() throws {
        let activity = Activity(
            name: "Test Activity",
            description: "Test Description",
            assignedMember: mockMembers[0],
            priority: .p0,
            status: .running,
            deadline: Date(timeIntervalSince1970: 1733356800)
        )
        
        let csvString = csvService.serializeActivities([activity])
        
        XCTAssertTrue(csvString.contains("Test Activity"))
        XCTAssertTrue(csvString.contains("Test Description"))
        XCTAssertTrue(csvString.contains("Vlad Alexa"))
        XCTAssertTrue(csvString.contains("p0"))
        XCTAssertTrue(csvString.contains("Running"))
    }
    
    func testSerializeActivities_EscapesCommas() throws {
        let activity = Activity(
            name: "Test, with comma",
            description: "Description, also with comma",
            assignedMember: mockMembers[0],
            priority: .p1,
            status: .running,
            deadline: Date()
        )
        
        let csvString = csvService.serializeActivities([activity])
        
        XCTAssertTrue(csvString.contains("\"Test, with comma\""))
        XCTAssertTrue(csvString.contains("\"Description, also with comma\""))
    }
    
    // MARK: - Team Parsing Tests
    
    func testParseTeams_ValidCSV() throws {
        let csvString = """
        name,team,email
        Vlad Alexa,Coal Miners,vlad@example.com
        Alex Trubacs,Coal Miners,alex@example.com
        """
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        XCTAssertEqual(teams.count, 2)
        XCTAssertEqual(teams[0].teamName, "Coal Miners")
        XCTAssertEqual(teams[0].member.name, "Vlad Alexa")
        XCTAssertEqual(teams[0].member.email, "vlad@example.com")
    }
    
    func testParseTeams_EmptyCSV() throws {
        let csvString = "name,team,email"
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        XCTAssertEqual(teams.count, 0)
    }
    
    // MARK: - Round-Trip Tests
    
    func testRoundTrip_SerializeAndParse() throws {
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
        
        XCTAssertEqual(parsedActivities.count, originalActivities.count)
        XCTAssertEqual(parsedActivities[0].name, originalActivities[0].name)
        XCTAssertEqual(parsedActivities[0].status, originalActivities[0].status)
        XCTAssertEqual(parsedActivities[1].outcome, originalActivities[1].outcome)
    }
    
    // MARK: - CSV Format Validation Tests
    
    func testActivitiesCSV_HeaderFormat() throws {
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
        
        XCTAssertGreaterThan(lines.count, 0, "CSV should have at least a header")
        XCTAssertEqual(lines[0], expectedHeader, "Activities CSV header must match documented format")
    }
    
    func testTeamsCSV_HeaderFormat() throws {
        // This test ensures teams parsing expects the correct column order
        let csvString = """
        name,team,email,manager
        Vlad Alexa,Coal Miners,vlad@example.com,manager@example.com
        """
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams[0].member.name, "Vlad Alexa")
        XCTAssertEqual(teams[0].teamName, "Coal Miners")
        XCTAssertEqual(teams[0].member.email, "vlad@example.com")
        XCTAssertEqual(teams[0].managerEmail, "manager@example.com", "Manager email should be parsed from 4th column")
    }
    
    func testActivitiesCSV_ManagerEmailColumn() throws {
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
        XCTAssertGreaterThan(lines.count, 1, "CSV should have header and data")
        let dataLine = lines[1]
        let columns = dataLine.components(separatedBy: ",")
        
        // Column 11 (12th column, 0-indexed) should be manager email
        XCTAssertGreaterThan(columns.count, 11, "CSV should have at least 12 columns")
        XCTAssertEqual(columns[11], "test.manager@example.com", "Manager email should be in column 12")
    }
    
    func testActivitiesCSV_RequiredColumnsOrder() throws {
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
        XCTAssertTrue(dataLine.starts(with: "12345678-1234-1234-1234-123456789ABC"), "Column 0: id")
        XCTAssertTrue(dataLine.contains("Test Activity"), "Column 1: name")
        XCTAssertTrue(dataLine.contains("Test Description"), "Column 2: description")
        XCTAssertTrue(dataLine.contains("Vlad Alexa"), "Column 3: memberName")
        XCTAssertTrue(dataLine.contains("p2"), "Column 4: priority")
        XCTAssertTrue(dataLine.contains("Completed"), "Column 5: status")
        XCTAssertTrue(dataLine.contains("Ahead"), "Column 6: outcome")
        XCTAssertTrue(dataLine.hasSuffix("boss@example.com"), "Column 11: manager (last column)")
    }
    
    func testTeamsCSV_WithoutManagerColumn() throws {
        // Verify backward compatibility: teams CSV without manager column should still parse
        let csvString = """
        name,team,email
        Vlad Alexa,Coal Miners,vlad@example.com
        """
        
        let teams = csvService.parseTeams(csvString: csvString)
        
        XCTAssertEqual(teams.count, 1)
        XCTAssertEqual(teams[0].member.name, "Vlad Alexa")
        XCTAssertNil(teams[0].managerEmail, "Manager email should be nil when column is absent")
    }
    
    func testActivitiesCSV_ColumnCountValidation() throws {
        // Ensure minimum 9 columns are required (up to deadline)
        let validCSV = """
        id,name,description,memberName,priority,status,outcome,createdAt,deadline
        96D53C78-1234-4567-8901-234567890001,Activity,Desc,Vlad Alexa,p0,Running,,2025-12-04T20:00:00Z,2025-12-04T22:00:00Z
        """
        
        let activities = csvService.parseActivities(csvString: validCSV, teamMembers: mockMembers)
        XCTAssertEqual(activities.count, 1, "Should parse activity with minimum 9 columns")
        
        let invalidCSV = """
        id,name,description,memberName,priority,status,outcome,createdAt
        96D53C78-1234-4567-8901-234567890001,Activity,Desc,Vlad Alexa,p0,Running,,2025-12-04T20:00:00Z
        """
        
        let noActivities = csvService.parseActivities(csvString: invalidCSV, teamMembers: mockMembers)
        XCTAssertEqual(noActivities.count, 0, "Should skip rows with less than 9 columns")
    }
}

//
//  MockCSVParsing.swift
//  valtaTests
//
//  Mock implementation of CSVParsing protocol for testing.
//
//  Created by vlad on 2025-12-18.
//

import Foundation
@testable import valta

// MARK: - Mock CSV Parsing

/// Mock implementation of CSVParsing for testing DataManager
class MockCSVParsing: CSVParsing {

    // MARK: - Stubbed Return Values

    var stubbedActivities: [Activity] = []
    var stubbedTeamMembers: [TeamMemberEntry] = []

    // MARK: - Call Tracking

    var parseActivitiesCalled = false
    var serializeActivitiesCalled = false
    var parseTeamsCalled = false

    var lastParsedActivitiesCSV: String?
    var lastSerializedActivities: [Activity]?
    var lastParsedTeamsCSV: String?

    // MARK: - CSVParsing Protocol

    func parseActivities(csvString: String, teamMembers: [TeamMember]) -> [Activity] {
        parseActivitiesCalled = true
        lastParsedActivitiesCSV = csvString
        return stubbedActivities
    }

    func serializeActivities(_ activities: [Activity]) -> String {
        serializeActivitiesCalled = true
        lastSerializedActivities = activities
        // Return simple CSV header for validation
        return "id,name,description,memberName,priority,status,outcome,createdAt,deadline,startedAt,completedAt,manager\n"
    }

    func parseTeams(csvString: String) -> [TeamMemberEntry] {
        parseTeamsCalled = true
        lastParsedTeamsCSV = csvString
        return stubbedTeamMembers
    }

    // MARK: - Test Helpers

    /// Resets all tracking state
    func reset() {
        parseActivitiesCalled = false
        serializeActivitiesCalled = false
        parseTeamsCalled = false
        lastParsedActivitiesCSV = nil
        lastSerializedActivities = nil
        lastParsedTeamsCSV = nil
    }
}

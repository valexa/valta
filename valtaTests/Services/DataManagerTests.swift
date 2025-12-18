//
//  DataManagerTests.swift
//  valtaTests
//
//  Unit tests for DataManager using dependency injection.
//  Tests loading, syncing, and error handling with mock dependencies.
//
//  Created by vlad on 2025-12-18.
//

import Testing
import Foundation
@testable import valta

@Suite("DataManager Tests")
struct DataManagerTests {

    // MARK: - Test Setup

    /// Creates a DataManager with mock dependencies
    func makeDataManager(
        mockStorage: MockStorageProvider = MockStorageProvider(),
        mockCSV: MockCSVParsing = MockCSVParsing()
    ) -> (DataManager, MockStorageProvider, MockCSVParsing) {
        // Configure mock storage to return empty CSV on missing data
        mockStorage.returnEmptyCSVOnMissingData = true

        let storageService = StorageService(provider: mockStorage)
        let dataManager = DataManager(storage: storageService, csv: mockCSV)
        return (dataManager, mockStorage, mockCSV)
    }

    // MARK: - Load Data Tests

    @Test("loadData calls CSV parsing")
    @MainActor
    func testLoadDataCallsCSVParsing() async {
        let (dataManager, mockStorage, mockCSV) = makeDataManager()

        // Setup: Store CSV data
        mockStorage.storedData["teams.csv"] = Data("name,team,email\nAlice,Team A,alice@test.com\n".utf8)
        mockStorage.storedData["activities.csv"] = Data("id,name,description\n".utf8)

        // Exercise
        await dataManager.loadData()

        // Verify: CSV parsing was called
        #expect(mockCSV.parseTeamsCalled)
        #expect(mockCSV.parseActivitiesCalled)
    }

    @Test("loadData populates teams from CSV")
    @MainActor
    func testLoadDataPopulatesTeams() async {
        let (dataManager, mockStorage, mockCSV) = makeDataManager()

        // Setup: Configure mock CSV to return team entries
        let member = TestDataFactory.makeMember(name: "Alice")
        let teamEntry = TeamMemberEntry(teamName: "Engineering", member: member, managerEmail: "manager@test.com")
        mockCSV.stubbedTeamMembers = [teamEntry]

        // Need to set storage data to avoid file not found error
        mockStorage.storedData["teams.csv"] = Data("data".utf8)
        mockStorage.storedData["activities.csv"] = Data("data".utf8)

        // Exercise
        await dataManager.loadData()

        // Verify: Teams populated
        #expect(dataManager.teams.count == 1)
        #expect(dataManager.teams.first?.name == "Engineering")
        #expect(dataManager.teams.first?.members.first?.name == "Alice")
    }

    @Test("loadData assigns activities to correct teams")
    @MainActor
    func testLoadDataAssignsActivitiesToTeams() async {
        let (dataManager, mockStorage, mockCSV) = makeDataManager()

        // Setup: Member and activity
        let member = TestDataFactory.makeMember(name: "Bob")
        let activity = TestDataFactory.makeActivity(name: "Review PR", assignedMember: member)

        mockCSV.stubbedTeamMembers = [TeamMemberEntry(teamName: "Backend", member: member, managerEmail: nil)]
        mockCSV.stubbedActivities = [activity]

        mockStorage.storedData["teams.csv"] = Data("data".utf8)
        mockStorage.storedData["activities.csv"] = Data("data".utf8)

        // Exercise
        await dataManager.loadData()

        // Verify: Activity assigned to team
        #expect(dataManager.teams.first?.activities.count == 1)
        #expect(dataManager.teams.first?.activities.first?.name == "Review PR")
    }

    @Test("loadData handles storage error gracefully")
    @MainActor
    func testLoadDataHandlesStorageError() async {
        let (dataManager, mockStorage, _) = makeDataManager()

        // Setup: Force download failure
        mockStorage.shouldFailDownload = true
        mockStorage.returnEmptyCSVOnMissingData = false

        // Exercise
        await dataManager.loadData()

        // Verify: Error captured, not crashed
        #expect(dataManager.errorMessage != nil)
        #expect(dataManager.teams.isEmpty)
    }

    // MARK: - Sync Tests

    @Test("syncActivities serializes activities")
    @MainActor
    func testSyncActivitiesSerializesActivities() async {
        let (dataManager, mockStorage, mockCSV) = makeDataManager()

        // Setup: Add team with activities
        let member = TestDataFactory.makeMember(name: "Charlie")
        let activity = TestDataFactory.makeActivity(name: "Deploy", assignedMember: member)
        let team = TestDataFactory.makeTeam(name: "DevOps", members: [member], activities: [activity])

        dataManager.teams = [team]

        // Exercise
        await dataManager.syncActivities()

        // Verify: Serialization was called
        #expect(mockCSV.serializeActivitiesCalled)
        #expect(mockCSV.lastSerializedActivities?.count == 1)
        #expect(mockCSV.lastSerializedActivities?.first?.name == "Deploy")

        // Verify: Upload was called
        #expect(mockStorage.uploadCalls.count == 1)
        #expect(mockStorage.uploadCalls.first?.path == "activities.csv")
    }

    @Test("syncActivities handles upload error")
    @MainActor
    func testSyncActivitiesHandlesUploadError() async {
        let (dataManager, mockStorage, mockCSV) = makeDataManager()

        // Setup: Force upload failure
        mockStorage.shouldFailUpload = true

        let member = TestDataFactory.makeMember(name: "Dave")
        let activity = TestDataFactory.makeActivity(assignedMember: member)
        dataManager.teams = [TestDataFactory.makeTeam(members: [member], activities: [activity])]

        // Exercise
        await dataManager.syncActivities()

        // Verify: Error captured
        #expect(dataManager.errorMessage == "Failed to save changes")
        #expect(mockCSV.serializeActivitiesCalled) // Still called before upload
    }

    // MARK: - State Management Tests

    @Test("loadData sets isLoading correctly")
    @MainActor
    func testLoadDataSetsIsLoading() async {
        let (dataManager, mockStorage, _) = makeDataManager()
        mockStorage.storedData["teams.csv"] = Data("".utf8)
        mockStorage.storedData["activities.csv"] = Data("".utf8)

        #expect(!dataManager.isLoading)

        await dataManager.loadData()

        #expect(!dataManager.isLoading) // Should be false after completion
    }

    @Test("syncActivities sets isSyncing correctly")
    @MainActor
    func testSyncActivitiesSetsSyncing() async {
        let (dataManager, _, _) = makeDataManager()

        #expect(!dataManager.isSyncing)

        await dataManager.syncActivities()

        #expect(!dataManager.isSyncing) // Should be false after completion
    }
}

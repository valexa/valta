//
//  DataManager.swift
//  Shared
//
//  Central manager for data synchronization.
//  Coordinates StorageService and CSVService.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import Observation

@Observable
class DataManager {
    static let shared = DataManager()

    var teams: [Team] = []
    var activities: [Activity] = []
    var currentUser: TeamMember?
    var isLoading = false
    var isSyncing = false
    var errorMessage: String?
    static let dataChangedNotification = Notification.Name("DataManagerDataChanged")

    // Force observers to refresh when nested mutations occur
    func notifyTeamsChanged() {
        // Reassign to trigger Observation write and invoke callback
        teams = teams
        NotificationCenter.default.post(name: Self.dataChangedNotification, object: nil)
    }

    private let storage = StorageService.shared
    private let csv = CSVService.shared

    // MARK: - Initialization

    @MainActor
    func loadData() async {
        // Don't load while syncing or already loading
        guard !isLoading && !isSyncing else {
            print("⏭️ Skipping loadData: isLoading=\(isLoading), isSyncing=\(isSyncing)")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            // 1. Fetch Teams (needed to map members to activities)
            let teamsCSV = try await storage.downloadTeams()
            let parsedMembers = csv.parseTeams(csvString: teamsCSV)

            // Group by team name
            let grouped = Dictionary(grouping: parsedMembers) { $0.teamName }

            // 2. Fetch Activities
            let activitiesCSV = try await storage.downloadActivities()
            let allMembers = parsedMembers.map { $0.member }
            let loadedActivities = csv.parseActivities(csvString: activitiesCSV, teamMembers: allMembers)

            // 3. Assign activities to teams
            self.teams = grouped.map { name, memberData in
                let teamMembers = memberData.map { $0.member }
                let managerEmail = memberData.first?.managerEmail // All members in same team should have same manager
                let teamActivities = loadedActivities.filter { activity in
                    teamMembers.contains { $0.id == activity.assignedMember.id }
                }
                return Team(name: name, members: teamMembers, activities: teamActivities, managerEmail: managerEmail)
            }.sorted { $0.name < $1.name }

            // Store all activities for global access
            self.activities = loadedActivities

            print("Successfully loaded \(self.teams.count) teams and \(activities.count) activities")

            // Notify listeners (e.g. ManagerAppState)
            NotificationCenter.default.post(name: Self.dataChangedNotification, object: nil)

        } catch {
            print("Error loading data: \(error.localizedDescription)")
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Actions

    func saveActivity(_ activity: Activity) async {
        // Update local state
        if let index = activities.findActivityIndex(byId: activity.id) {
            activities[index] = activity
        } else {
            activities.append(activity)
        }

        // Sync to cloud
        await syncActivities()
    }

    func syncActivities() async {
        isSyncing = true
        isLoading = true

        // Extract all activities from all teams
        let allActivities = teams.flatMap { $0.activities }
        print("📤 Syncing \(allActivities.count) activities to Firebase...")
        
        let csvString = csv.serializeActivities(allActivities)

        do {
            try await storage.uploadActivities(csvString)
            print("✅ Successfully uploaded \(allActivities.count) activities")
        } catch {
            print("❌ Error uploading activities: \(error.localizedDescription)")
            errorMessage = "Failed to save changes"
        }

        isLoading = false
        isSyncing = false
    }

    func refresh() async {
        await loadData()
    }
}

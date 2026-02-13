//
//  DataManager.swift
//  Shared
//
//  Central manager for data synchronization.
//  Coordinates StorageService and CSVService.
//  Includes conflict detection and merge on concurrent saves.
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

    /// Activities that have been locally mutated and need to be preserved during conflict merge
    var pendingMutations: [Activity] = []

    // Force observers to refresh when nested mutations occur
    func notifyTeamsChanged() {
        // Reassign to trigger Observation write and invoke callback
        teams = teams
        NotificationCenter.default.post(name: Self.dataChangedNotification, object: nil)
    }

    // MARK: - Dependencies (injectable for testing)

    private let storage: StorageService
    private let csv: CSVParsing

    // MARK: - Initialization

    init(storage: StorageService = .shared, csv: CSVParsing = CSVService.shared) {
        self.storage = storage
        self.csv = csv
    }

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

            // 2. Fetch Activities with timestamp for conflict tracking
            let (activitiesCSV, _) = try await storage.downloadActivitiesWithTimestamp()
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

        do {
            // Check for remote conflict before uploading
            let hasConflict = try await storage.hasRemoteConflict()

            var activitiesToUpload: [Activity]

            if hasConflict && !pendingMutations.isEmpty {
                print("⚠️ Remote conflict detected — merging before upload...")

                // Re-download fresh data
                let (freshCSV, _) = try await storage.downloadActivitiesWithTimestamp()
                let teamsCSV = try await storage.downloadTeams()
                let parsedMembers = csv.parseTeams(csvString: teamsCSV)
                let allMembers = parsedMembers.map { $0.member }
                var freshActivities = csv.parseActivities(csvString: freshCSV, teamMembers: allMembers)

                // Merge: apply each pending mutation by activity ID onto fresh data
                for mutatedActivity in pendingMutations {
                    freshActivities = mergeActivity(mutatedActivity, into: freshActivities)
                }

                activitiesToUpload = freshActivities

                // Update local state with merged data
                await updateLocalState(with: freshActivities, parsedMembers: parsedMembers)

                print("✅ Merged \(pendingMutations.count) local mutation(s) with remote data")
            } else {
                // No conflict — upload current local state
                activitiesToUpload = teams.flatMap { $0.activities }
            }

            print("📤 Syncing \(activitiesToUpload.count) activities to Firebase...")
            let csvString = csv.serializeActivities(activitiesToUpload)
            try await storage.uploadActivities(csvString)
            print("✅ Successfully uploaded \(activitiesToUpload.count) activities")

            // Clear pending mutations after successful sync
            pendingMutations = []

        } catch {
            print("❌ Error uploading activities: \(error.localizedDescription)")
            errorMessage = "Failed to save changes"
        }

        isLoading = false
        isSyncing = false
    }

    // MARK: - Merge

    /// Replaces an activity by ID in a list, or appends it if not found
    func mergeActivity(_ mutated: Activity, into activities: [Activity]) -> [Activity] {
        var result = activities
        if let index = result.findActivityIndex(byId: mutated.id) {
            result[index] = mutated
        } else {
            result.append(mutated)
        }
        return result
    }

    /// Updates local teams and activities from fresh parsed data
    @MainActor
    private func updateLocalState(with freshActivities: [Activity], parsedMembers: [TeamMemberEntry]) {
        let grouped = Dictionary(grouping: parsedMembers) { $0.teamName }

        self.teams = grouped.map { name, memberData in
            let teamMembers = memberData.map { $0.member }
            let managerEmail = memberData.first?.managerEmail
            let teamActivities = freshActivities.filter { activity in
                teamMembers.contains { $0.id == activity.assignedMember.id }
            }
            return Team(name: name, members: teamMembers, activities: teamActivities, managerEmail: managerEmail)
        }.sorted { $0.name < $1.name }

        self.activities = freshActivities

        NotificationCenter.default.post(name: Self.dataChangedNotification, object: nil)
    }

    func refresh() async {
        await loadData()
    }
}

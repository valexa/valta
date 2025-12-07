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
    var errorMessage: String?
    var onTeamsChanged: (() -> Void)?
    
    // Force observers to refresh when nested mutations occur
    func notifyTeamsChanged() {
        // Reassign to trigger Observation write and invoke callback
        teams = teams
        onTeamsChanged?()
    }
    
    private let storage = StorageService.shared
    private let csv = CSVService.shared
    
    // MARK: - Initialization
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Fetch Teams (needed to map members to activities)
            let teamsCSV = try await storage.downloadTeams()
            let parsedMembers = csv.parseTeams(csvString: teamsCSV)
            
            // Group by team name
            let grouped = Dictionary(grouping: parsedMembers, by: { $0.teamName })
            
            // 2. Fetch Activities
            let activitiesCSV = try await storage.downloadActivities()
            let allMembers = parsedMembers.map { $0.member }
            let loadedActivities = csv.parseActivities(csvString: activitiesCSV, teamMembers: allMembers)
            
            // 3. Assign activities to teams
            self.teams = grouped.map { (name, members) in
                let teamMembers = members.map { $0.member }
                let teamActivities = loadedActivities.filter { activity in
                    teamMembers.contains(where: { $0.id == activity.assignedMember.id })
                }
                return Team(name: name, members: teamMembers, activities: teamActivities)
            }.sorted(by: { $0.name < $1.name })
            
            // Store all activities for global access
            self.activities = loadedActivities
            
            print("Successfully loaded \(self.teams.count) teams and \(activities.count) activities")
            
        } catch {
            print("Error loading data: \(error.localizedDescription)")
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Actions
    
    func saveActivity(_ activity: Activity) async {
        // Update local state
        if let index = activities.firstIndex(where: { $0.id == activity.id }) {
            activities[index] = activity
        } else {
            activities.append(activity)
        }
        
        // Sync to cloud
        await syncActivities()
    }
    
    func syncActivities() async {
        isLoading = true
        
        // Extract all activities from all teams
        let allActivities = teams.flatMap { $0.activities }
        let csvString = csv.serializeActivities(allActivities)
        
        do {
            try await storage.uploadActivities(csvString)
            print("Successfully uploaded activities")
        } catch {
            print("Error uploading activities: \(error.localizedDescription)")
            errorMessage = "Failed to save changes"
        }
        
        isLoading = false
    }
    
    func refresh() async {
        await loadData()
    }
}


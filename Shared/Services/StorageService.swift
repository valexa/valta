//
//  StorageService.swift
//  Shared
//
//  Handles Firebase Storage operations for CSV files.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import FirebaseStorage
import Combine

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    private var storage: Storage {
        Storage.storage()
    }
    private let activitiesPath = "activities.csv"
    private let teamsPath = "teams.csv"
    
    @Published var isSyncing = false
    @Published var lastSyncError: Error?
    
    // MARK: - Download
    
    func downloadTeams() async throws -> String {
        let ref = storage.reference().child(teamsPath)
        // Max size 1MB
        let data = try await ref.data(maxSize: 1 * 1024 * 1024)
        guard let string = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return string
    }
    
    func downloadActivities() async throws -> String {
        let ref = storage.reference().child(activitiesPath)
        let data = try await ref.data(maxSize: 1 * 1024 * 1024)
        guard let string = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return string
    }
    
    // MARK: - Upload
    
    func uploadActivities(_ csvString: String) async throws {
        guard let data = csvString.data(using: .utf8) else { return }
        let ref = storage.reference().child(activitiesPath)
        let metadata = StorageMetadata()
        metadata.contentType = "text/csv"
        
        _ = try await ref.putDataAsync(data, metadata: metadata)
    }
}

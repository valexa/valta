//
//  StorageService.swift
//  Shared
//
//  Handles Firebase Storage operations for CSV files.
//  Exposes provider for testing.
//  Includes timestamp tracking for conflict detection.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import FirebaseStorage
import Observation

// MARK: - Storage Provider Protocol

protocol StorageProvider {
    func downloadData(path: String, maxSize: Int64) async throws -> Data
    func uploadData(path: String, data: Data, metadata: [String: String]?) async throws
    func fetchMetadata(path: String) async throws -> Date
}

// MARK: - Firebase Implementation

struct FirebaseStorageProvider: StorageProvider {
    private var storage: Storage {
        Storage.storage()
    }

    func downloadData(path: String, maxSize: Int64) async throws -> Data {
        let ref = storage.reference().child(path)
        return try await ref.data(maxSize: maxSize)
    }

    func uploadData(path: String, data: Data, metadata: [String: String]?) async throws {
        let ref = storage.reference().child(path)
        let storageMetadata = StorageMetadata()
        if let contentType = metadata?["contentType"] {
            storageMetadata.contentType = contentType
        }
        if let cacheControl = metadata?["cacheControl"] {
            storageMetadata.cacheControl = cacheControl
        }
        _ = try await ref.putDataAsync(data, metadata: storageMetadata)
    }

    func fetchMetadata(path: String) async throws -> Date {
        let ref = storage.reference().child(path)
        let metadata = try await ref.getMetadata()
        return metadata.updated ?? metadata.timeCreated ?? Date()
    }
}

// MARK: - Storage Service

@Observable
class StorageService {
    static let shared = StorageService()

    var provider: StorageProvider
    private let activitiesPath = "activities.csv"
    private let teamsPath = "teams.csv"

    var isSyncing = false
    var lastSyncError: Error?

    /// Tracks the last known remote modification time for conflict detection
    var lastKnownRemoteTimestamp: Date?

    init(provider: StorageProvider = FirebaseStorageProvider()) {
        self.provider = provider
    }

    // MARK: - Download

    func downloadTeams() async throws -> String {
        // Max size 1MB
        let data = try await provider.downloadData(path: teamsPath, maxSize: 1 * 1024 * 1024)
        guard let string = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return string
    }

    func downloadActivities() async throws -> String {
        let data = try await provider.downloadData(path: activitiesPath, maxSize: 1 * 1024 * 1024)
        guard let string = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return string
    }

    /// Downloads activities and fetches the remote timestamp for conflict tracking
    func downloadActivitiesWithTimestamp() async throws -> (csv: String, remoteTimestamp: Date) {
        let csv = try await downloadActivities()
        let timestamp = try await provider.fetchMetadata(path: activitiesPath)
        lastKnownRemoteTimestamp = timestamp
        return (csv, timestamp)
    }

    // MARK: - Metadata

    /// Fetches the current remote modification timestamp for activities.csv
    func fetchActivitiesTimestamp() async throws -> Date {
        return try await provider.fetchMetadata(path: activitiesPath)
    }

    /// Returns true if the remote file has been modified since our last download
    func hasRemoteConflict() async throws -> Bool {
        guard let lastKnown = lastKnownRemoteTimestamp else {
            // First time — no baseline, no conflict
            return false
        }
        let remoteTimestamp = try await fetchActivitiesTimestamp()
        return remoteTimestamp > lastKnown
    }

    // MARK: - Upload

    func uploadActivities(_ csvString: String) async throws {
        guard let data = csvString.data(using: .utf8) else { return }
        try await provider.uploadData(path: activitiesPath, data: data, metadata: [
            "contentType": "text/csv",
            "cacheControl": "no-cache"
        ])
        // Update timestamp after successful upload
        lastKnownRemoteTimestamp = try? await fetchActivitiesTimestamp()
    }
}

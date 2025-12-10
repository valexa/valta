//
//  StorageService.swift
//  Shared
//
//  Handles Firebase Storage operations for CSV files.
//  Exposes provider for testing.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import FirebaseStorage
import Combine

// MARK: - Storage Provider Protocol

protocol StorageProvider {
    func downloadData(path: String, maxSize: Int64) async throws -> Data
    func uploadData(path: String, data: Data, metadata: [String: String]?) async throws
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
}

// MARK: - Storage Service

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    var provider: StorageProvider
    private let activitiesPath = "activities.csv"
    private let teamsPath = "teams.csv"
    
    @Published var isSyncing = false
    @Published var lastSyncError: Error?
    
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
    
    // MARK: - Upload
    
    func uploadActivities(_ csvString: String) async throws {
        guard let data = csvString.data(using: .utf8) else { return }
        try await provider.uploadData(path: activitiesPath, data: data, metadata: [
            "contentType": "text/csv",
            "cacheControl": "no-cache"
        ])
    }
}

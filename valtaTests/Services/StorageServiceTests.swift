//
//  StorageServiceTests.swift
//  valtaTests
//
//  Unit tests for StorageService
//
//  Created by vlad on 2025-12-05.
//

import Testing
import Foundation
@testable import valta

// MARK: - Tests

@MainActor
struct StorageServiceTests {
    var service: StorageService
    var mockProvider: MockStorageProvider
    
    init() {
        mockProvider = MockStorageProvider()
        service = StorageService(provider: mockProvider)
    }
    
    // MARK: - Download Tests
    
    @Test func testDownloadTeams_Success() async throws {
        // Given
        let csvString = "name,team,email\nVlad,Dev,vlad@example.com"
        mockProvider.storedData["teams.csv"] = csvString.data(using: .utf8)
        
        // When
        let result = try await service.downloadTeams()
        
        // Then
        #expect(result == csvString)
    }
    
    @Test func testDownloadTeams_Failure() async {
        // Given
        mockProvider.shouldFailDownload = true
        
        // When/Then
        await #expect(throws: URLError.self) {
            _ = try await service.downloadTeams()
        }
    }
    
    @Test func testDownloadActivities_Success() async throws {
        // Given
        let csvString = "id,name,status\n1,Test,Running"
        mockProvider.storedData["activities.csv"] = csvString.data(using: .utf8)
        
        // When
        let result = try await service.downloadActivities()
        
        // Then
        #expect(result == csvString)
    }
    
    // MARK: - Upload Tests
    
    @Test func testUploadActivities_Success() async throws {
        // Given
        let csvString = "id,name,status\n1,Test,Running"
        
        // When
        try await service.uploadActivities(csvString)
        
        // Then
        #expect(mockProvider.uploadCalls.count == 1)
        
        if let call = mockProvider.uploadCalls.first {
            #expect(call.path == "activities.csv")
            #expect(call.metadata?["contentType"] == "text/csv")
            
            let uploadedString = String(data: call.data, encoding: .utf8)
            #expect(uploadedString == csvString)
        }
    }
    
    @Test func testUploadActivities_Failure() async {
        // Given
        mockProvider.shouldFailUpload = true
        let csvString = "data"
        
        // When/Then
        await #expect(throws: URLError.self) {
            try await service.uploadActivities(csvString)
        }
    }
}

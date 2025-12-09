//
//  StorageServiceTests.swift
//  valtaTests
//
//  Unit tests for StorageService
//
//  Created by vlad on 2025-12-05.
//

import XCTest
@testable import valta

// MARK: - Mock Storage Provider

class MockStorageProvider: StorageProvider {
    var storedData: [String: Data] = [:]
    var uploadCalls: [(path: String, data: Data, metadata: [String: String]?)] = []
    
    var shouldFailDownload = false
    var shouldFailUpload = false
    
    func downloadData(path: String, maxSize: Int64) async throws -> Data {
        if shouldFailDownload {
            throw URLError(.fileDoesNotExist)
        }
        guard let data = storedData[path] else {
            throw URLError(.fileDoesNotExist)
        }
        return data
    }
    
    func uploadData(path: String, data: Data, metadata: [String: String]?) async throws {
        if shouldFailUpload {
            throw URLError(.cannotWriteToFile)
        }
        storedData[path] = data
        uploadCalls.append((path, data, metadata))
    }
}

// MARK: - Tests

final class StorageServiceTests: XCTestCase {
    var service: StorageService!
    var mockProvider: MockStorageProvider!
    
    override func setUp() {
        super.setUp()
        mockProvider = MockStorageProvider()
        service = StorageService(provider: mockProvider)
    }
    
    override func tearDown() {
        service = nil
        mockProvider = nil
        super.tearDown()
    }
    
    // MARK: - Download Tests
    
    func testDownloadTeams_Success() async throws {
        // Given
        let csvString = "name,team,email\nVlad,Dev,vlad@example.com"
        mockProvider.storedData["teams.csv"] = csvString.data(using: .utf8)
        
        // When
        let result = try await service.downloadTeams()
        
        // Then
        XCTAssertEqual(result, csvString)
    }
    
    func testDownloadTeams_Failure() async {
        // Given
        mockProvider.shouldFailDownload = true
        
        // When/Then
        do {
            _ = try await service.downloadTeams()
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
    
    func testDownloadActivities_Success() async throws {
        // Given
        let csvString = "id,name,status\n1,Test,Running"
        mockProvider.storedData["activities.csv"] = csvString.data(using: .utf8)
        
        // When
        let result = try await service.downloadActivities()
        
        // Then
        XCTAssertEqual(result, csvString)
    }
    
    // MARK: - Upload Tests
    
    func testUploadActivities_Success() async throws {
        // Given
        let csvString = "id,name,status\n1,Test,Running"
        
        // When
        try await service.uploadActivities(csvString)
        
        // Then
        XCTAssertEqual(mockProvider.uploadCalls.count, 1)
        let call = mockProvider.uploadCalls[0]
        XCTAssertEqual(call.path, "activities.csv")
        XCTAssertEqual(call.metadata?["contentType"], "text/csv")
        
        let uploadedString = String(data: call.data, encoding: .utf8)
        XCTAssertEqual(uploadedString, csvString)
    }
    
    func testUploadActivities_Failure() async {
        // Given
        mockProvider.shouldFailUpload = true
        let csvString = "data"
        
        // When/Then
        do {
            try await service.uploadActivities(csvString)
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}

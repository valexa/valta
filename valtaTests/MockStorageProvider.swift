
import Foundation
@testable import valta

// MARK: - Mock Storage Provider

class MockStorageProvider: StorageProvider {
    var storedData: [String: Data] = [:]
    var uploadCalls: [(path: String, data: Data, metadata: [String: String]?)] = []
    
    // Track call counts
    var downloadCallCount = 0

    var shouldFailDownload = false
    var shouldFailUpload = false

    func downloadData(path: String, maxSize: Int64) async throws -> Data {
        downloadCallCount += 1
        
        if shouldFailDownload {
            throw URLError(.fileDoesNotExist)
        }
        
        guard let data = storedData[path] else {
            // Return empty CSV headers by default if not found (logic merged from MockStorageProviderDiff)
            // This is useful for tests that need valid initial state without setup
            if path.contains("teams") {
                return "id,name,members,managerEmail\n".data(using: .utf8)!
            } else {
                return "id,name,description,deadline,priority,status,assignedMemberId,createdAt\n".data(using: .utf8)!
            }
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

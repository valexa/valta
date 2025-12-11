
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
    
    /// When true, returns empty CSV headers if data not found (useful for tests needing valid initial state).
    /// When false (default), throws URLError.fileDoesNotExist if data not found (stricter test behavior).
    var returnEmptyCSVOnMissingData = false

    func downloadData(path: String, maxSize: Int64) async throws -> Data {
        downloadCallCount += 1
        
        if shouldFailDownload {
            throw URLError(.fileDoesNotExist)
        }
        
        guard let data = storedData[path] else {
            // Only return empty CSV if explicitly configured
            if returnEmptyCSVOnMissingData {
                if path.contains("teams") {
                    return "id,name,members,managerEmail\n".data(using: .utf8)!
                } else {
                    return "id,name,description,deadline,priority,status,assignedMemberId,createdAt\n".data(using: .utf8)!
                }
            }
            // Default: throw error for missing data (stricter behavior)
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

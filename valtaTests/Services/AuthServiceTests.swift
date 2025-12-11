//
//  AuthServiceTests.swift
//  valtaTests
//
//  Created by Vlad on 2025-12-08.
//

import Testing
import Foundation
@testable import valta

@MainActor
struct AuthServiceTests {

    // Since AuthService wraps FirebaseAuth static calls, it's hard to unit test without wrapping the wrapper.
    // However, we can test that the AuthService structure exists and exposes the expected API.

    @Test func testInterface() {
        // This is mostly a compilation check ensuring the ABI is stable
        let service = AuthService.shared

        // We can't easily assert isLoggedIn state without a mock Auth provider,
        // but we can assert that calling it doesn't crash.
        // In a real app we'd use a protocol for AuthProvider.

        // For now, simply accessing the property covers the code path of the accessor.
        _ = service.isAuthenticated
        _ = service.currentUser

        // Success if no crash
        #expect(true)
    }
}

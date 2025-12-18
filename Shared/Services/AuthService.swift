//
//  AuthService.swift
//  Shared
//
//  Handles Firebase Anonymous Authentication.
//
//  Created by vlad on 2025-12-04.
//

import Foundation
import FirebaseAuth
import Observation

// MARK: - Auth Providing Protocol

/// Protocol for authentication operations
@MainActor
protocol AuthProviding {
    var isAuthenticated: Bool { get }
    func signInAnonymously() async throws
}

// MARK: - Auth Service

@Observable
@MainActor
final class AuthService: AuthProviding {
    static let shared = AuthService()

    var isAuthenticated = false
    var currentUser: User?

    private init() {
        // Initialization happens before FirebaseApp.configure()
        // Check auth state in signInAnonymously() instead
    }

    func signInAnonymously() async throws {
        // Check if already signed in
        if let user = Auth.auth().currentUser {
            self.currentUser = user
            self.isAuthenticated = true
            print("Already signed in with user ID: \(user.uid)")
            return
        }

        // Sign in anonymously
        let result = try await Auth.auth().signInAnonymously()
        self.currentUser = result.user
        self.isAuthenticated = true
        print("Signed in anonymously with user ID: \(result.user.uid)")
    }
}

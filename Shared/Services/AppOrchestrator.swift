//
//  AppOrchestrator.swift
//  Shared
//
//  Manages the application startup sequence and ensures Firebase is fully configured.
//

import Foundation
import Observation
import Firebase

@Observable
@MainActor
final class AppOrchestrator {
    static let shared = AppOrchestrator()
    
    private(set) var isFirebaseReady = false
    
    private init() {}
    
    /// Configures Firebase and signals readiness.
    /// MUST be called once from AppDelegate.applicationDidFinishLaunching.
    func configureFirebase() {
        guard !isFirebaseReady else { return }
        
        print("🚀 AppOrchestrator: Configuring Firebase...")
        FirebaseApp.configure()
        isFirebaseReady = true
        print("✅ AppOrchestrator: Firebase configured and ready.")
    }
}

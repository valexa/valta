//
//  valtaManagerApp.swift
//  valtaManager Manager App entry point
//  Synopsis: two tabs, teams and requests
//  Teams tab enables creation and management of teams and their members
//  Requests tab allows viewing and managing requests from team members
//
//  Created by vlad on 04/12/2025.
//

import SwiftUI
import AppKit
import Firebase
import FirebaseAuth

@main
struct valtaManagerApp: App {

    init() {
        FirebaseApp.configure()
    }

#if os(iOS) || os(visionOS) || os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
#endif

#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
    
    @State private var dataManager = DataManager.shared
    @State private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .environment(authService)
                .task {
                    do {
                        try await authService.signInAnonymously()
                        await dataManager.loadData()
                    } catch {
                        print("Authentication error: \(error.localizedDescription)")
                    }
                }
        }
    }
}

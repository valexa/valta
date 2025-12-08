//
//  valtaApp.swift
//  valta team member app entry point
//  Synopsis: 3 tabs, activities, team and log
//  Activities tab shows assigned activities and their status
//  Team tab displays all running or pending activities assigned to the user's team
//  Log tab provides a history of completed activities
//  Created by vlad on 04/12/2025.
//

import SwiftUI
import AppKit
import Firebase
import FirebaseAuth

@main
struct valtaApp: App {

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
    @State private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .focusEffectDisabled()
                .environment(dataManager)
                .environment(authService)
                .environment(notificationService)
                .task {
                    do {
                        try await authService.signInAnonymously()
                        await dataManager.loadData()
                        
                        // Request notification permissions and register for remote notifications
                        let granted = await notificationService.requestNotificationPermission()
                        if granted {
                            print("✅ Notification permissions granted")
                        } else {
                            print("⚠️ Notification permissions denied")
                        }
                        
                        // Start periodic refresh every 60 seconds
                        while true {
                            try? await Task.sleep(nanoseconds: 60 * 1_000_000_000) // 60 seconds
                            await dataManager.loadData()
                        }
                    } catch {
                        print("Authentication error: \(error.localizedDescription)")
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}


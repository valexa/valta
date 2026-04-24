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
import Firebase
import FirebaseAuth

@main
struct valtaManagerApp: App {

#if os(iOS) || os(visionOS) || os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
#endif

#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

    @State private var orchestrator = AppOrchestrator.shared
    @State private var dataManager = DataManager.shared
    @State private var authService = AuthService.shared
    @State private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if orchestrator.isFirebaseReady {
                    ContentView()
                        .focusEffectDisabled()
                        .environment(dataManager)
                        .environment(authService)
                        .environment(notificationService)
                        .task {
                            // Clear dock badge immediately on launch (reset any stale notification-set badges)
                            #if os(macOS)
                            NSApplication.shared.dockTile.badgeLabel = nil
                            #endif

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
                                    try await Task.sleep(nanoseconds: 60 * 1_000_000_000) // 60 seconds
                                    await dataManager.loadData()
                                }
                            } catch is CancellationError {
                                print("loadData Task cancelled")
                            } catch {
                                print("Authentication error: \(error.localizedDescription)")
                            }
                        }
                } else {
                    // Premium loading state during critical Firebase initialization
                    ZStack {
                        Color(NSColor.windowBackgroundColor)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(.circular)
                    }
                    .frame(minWidth: 400, minHeight: 300)
                }
            }
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        #endif
    }
}

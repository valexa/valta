//
//  ContentView.swift
//  valta
//
//  Main content view with onboarding and tab navigation.
//  Three tabs: Activities, Team, and Log.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = TeamMemberAppState()

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                TeamMemberOnboardingView()
            }
        }
        .environment(appState)
        .onChange(of: appState.myActivities.allPending.count) { _, newCount in
            updateDockBadge(count: newCount)
        }
        .onChange(of: appState.dataVersion) { _, _ in
            // Also update when dataVersion changes (covers mutations not detected by count change)
            updateDockBadge(count: appState.myActivities.allPending.count)
        }
        .onAppear {
            updateDockBadge(count: appState.myActivities.allPending.count)

            // Register token if member is already selected
            if let member = appState.currentMember {
                print("🔄 App launched with member: \(member.name) (\(member.email))")
                Task {
                    await NotificationService.shared.registerMemberEmail(member.email)
                }
            } else {
                print("⚠️ App launched but no member selected yet")
            }
        }
    }

    private func updateDockBadge(count: Int) {
        #if os(macOS)
        DispatchQueue.main.async {
            if count > 0 {
                NSApplication.shared.dockTile.badgeLabel = "\(count)"
            } else {
                NSApplication.shared.dockTile.badgeLabel = nil
            }
        }
        #endif
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(TeamMemberAppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        TabView(selection: $state.selectedTab) {
            ActivitiesTab()
                .tabItem {
                    Label("My Activities", systemImage: "person.fill.checkmark")
                }
                .tag(TeamMemberTab.activities)
                .badge(appState.myActiveCount)

            TeamTab()
                .tabItem {
                    Label("Team", systemImage: "person.3.fill")
                }
                .tag(TeamMemberTab.team)

            LogTab()
                .tabItem {
                    Label("Log", systemImage: "list.bullet.clipboard.fill")
                }
                .tag(TeamMemberTab.log)
        }
        .tabViewStyle(.sidebarAdaptable)
        .frame(minWidth: 1000, minHeight: 800)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

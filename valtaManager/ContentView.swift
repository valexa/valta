//
//  ContentView.swift
//  valtaManager
//
//  Main content view with tab navigation between Teams and Requests.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct ContentView: View {
    @State private var appState = ManagerAppState()

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                ManagerOnboardingView()
            }
        }
        .environment(appState)
        .onChange(of: appState.managerPendingActivities.count) { _, newCount in
            updateDockBadge(count: newCount)
        }
        .onChange(of: appState.dataVersion) { _, _ in
            // Also update when dataVersion changes (covers mutations not detected by count change)
            updateDockBadge(count: appState.managerPendingActivities.count)
        }
        .onAppear {
            updateDockBadge(count: appState.managerPendingActivities.count)
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
    @Environment(ManagerAppState.self) private var appState

    var body: some View {
        TabView {
            TabSection("Status") {
                Tab("All Activities", systemImage: AppSymbols.tabAllActivities) {
                    ActivitiesTab()
                }
                .badge(appState.totalActivities)

                Tab("Running", systemImage: AppSymbols.tabRunning) {
                    ActivitiesTab(statsFilter: .status(.running))
                }
                .badge(appState.runningCount)

                Tab("Pending", systemImage: AppSymbols.tabPending) {
                    ActivitiesTab(statsFilter: .pending)
                }
                .badge(appState.pendingCount)

                Tab("Completed", systemImage: AppSymbols.tabCompleted) {
                    ActivitiesTab(statsFilter: .status(.completed))
                }
                .badge(appState.completedCount)
            }

            Tab("Requests", systemImage: AppSymbols.tabRequests) {
                RequestsTab()
            }
            .badge(appState.managerPendingActivities.count)

            Tab("Analytics", systemImage: AppSymbols.tabAnalytics) {
                AnalyticsTab()
            }

            TabSection("Team Members") {
                ForEach(appState.team.members) { member in
                    Tab(member.name, systemImage: AppSymbols.tabPerson) {
                        ActivitiesTab(member: member)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .frame(minWidth: 1000, minHeight: 800)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

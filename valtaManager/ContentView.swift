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
    @State private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(appState)
        .onChange(of: appState.pendingActivities.count) { _, newCount in
            updateDockBadge(count: newCount)
        }
        .onAppear {
            updateDockBadge(count: appState.pendingActivities.count)
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
    @Environment(AppState.self) private var appState
    
    var body: some View {
        TabView {
            TabSection("Status") {
                Tab("All Activities", systemImage: "list.bullet.rectangle") {
                    TeamsTab()
                }
                .badge(appState.totalActivities)
                
                Tab("Running", systemImage: "play.fill") {
                    TeamsTab(statsFilter: .status(.running))
                }
                .badge(appState.runningCount)
                
                Tab("Pending", systemImage: "clock.fill") {
                    TeamsTab(statsFilter: .pending)
                }
                .badge(appState.pendingCount)
                
                Tab("Completed", systemImage: "checkmark.circle.fill") {
                    TeamsTab(statsFilter: .status(.completed))
                }
                .badge(appState.completedCount)
            }
            
            Tab("Requests", systemImage: "checkmark.rectangle.stack") {
                RequestsTab()
            }
            .badge(appState.pendingActivities.count)
            
            TabSection("Team Members") {
                ForEach(appState.team.members) { member in
                    Tab(member.name, systemImage: "person") {
                        TeamsTab(member: member)
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

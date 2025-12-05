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
        .frame(minWidth: 800, minHeight: 550)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

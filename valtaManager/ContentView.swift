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
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        @Bindable var state = appState
        
        TabView(selection: $state.selectedTab) {
            TeamsTab()
                .tabItem {
                    Label("Teams", systemImage: "person.3.fill")
                }
                .tag(AppTab.teams)
            
            RequestsTab()
                .tabItem {
                    Label("Requests", systemImage: "tray.full.fill")
                }
                .tag(AppTab.requests)
                .badge(appState.completionRequests.count)
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

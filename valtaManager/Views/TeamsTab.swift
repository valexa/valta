//
//  TeamsTab.swift
//  valtaManager
//
//  Teams tab showing team overview, activity dashboard, and member management.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

/// Filter type for stats grid - supports grouping pending statuses
enum StatsFilter: Equatable {
    case status(ActivityStatus)
    case pending  // Matches both teamMemberPending and managerPending
    
    func matches(_ activity: Activity) -> Bool {
        switch self {
        case .status(let status):
            return activity.status == status
        case .pending:
            return activity.status == .teamMemberPending || activity.status == .managerPending
        }
    }
}

struct TeamsTab: View {
    @Environment(AppState.self) private var appState
    @State private var searchText: String = ""
    @State private var statusFilter: ActivityStatus? = nil
    @State private var statsFilter: StatsFilter? = nil
    @State private var priorityFilter: ActivityPriority? = nil
    @State private var outcomeFilter: ActivityOutcome? = nil
    @State private var memberFilter: TeamMember? = nil
    
    // Allow initializing with specific filters from the sidebar
    init(member: TeamMember? = nil, statsFilter: StatsFilter? = nil) {
        _memberFilter = State(wrappedValue: member)
        _statsFilter = State(wrappedValue: statsFilter)
    }
    
    var filteredActivities: [Activity] {
        appState.team.activities.filter { activity in
            let matchesSearch = searchText.isEmpty ||
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                activity.assignedMember.name.localizedCaseInsensitiveContains(searchText)
            
            // Stats filter takes precedence if set
            let matchesStats: Bool
            if let statsFilter = statsFilter {
                matchesStats = statsFilter.matches(activity)
            } else {
                matchesStats = statusFilter == nil || activity.status == statusFilter
            }
            
            let matchesPriority = priorityFilter == nil || activity.priority == priorityFilter
            
            let matchesOutcome = outcomeFilter == nil || activity.outcome == outcomeFilter
            
            let matchesMember = memberFilter == nil || activity.assignedMember.id == memberFilter?.id
            
            return matchesSearch && matchesStats && matchesPriority && matchesOutcome && matchesMember
        }
    }
    
    var body: some View {
        @Bindable var state = appState
        
        // Main content - Activity dashboard
        VStack(spacing: 0) {
            
            // Activity list
            if filteredActivities.isEmpty {
                EmptyActivityView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredActivities) { activity in
                            ActivityCard(activity: activity)
                        }
                    }
                    .padding()
                }
            }
        }

        .navigationTitle(memberFilter?.name ?? "Activity Dashboard")
        .searchable(text: $searchText, placement: .toolbarPrincipal, prompt: "Search activities...")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                // Status Filter
                StatusFilterMenu(selection: $statusFilter)
                // Priority Filter
                PriorityFilterMenu(selection: $priorityFilter)
                // Outcome Filter
                OutcomeFilterMenu(selection: $outcomeFilter)
            }

            ToolbarItem(placement: .automatic) {
                // New Activity
                Button(action: { appState.showingNewActivitySheet = true }) {
                    Label("New Activity", systemImage: "plus")
                }
            }

        }
        .sheet(isPresented: $state.showingNewActivitySheet) {
            NewActivitySheet()
        }
    }
}


// MARK: - Dashboard Header

// MARK: - Dashboard Header
// Removed: filters and search moved to toolbar


// MARK: - Empty State

struct EmptyActivityView: View {
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 16) {
            Image(symbol: AppSymbols.tray)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Activities")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first activity to get started")
                .foregroundColor(.secondary)
            
            Button(action: { appState.showingNewActivitySheet = true }) {
                HStack(spacing: 6) {
                    Image(symbol: AppSymbols.plus)
                    Text("New Activity")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    TeamsTab()
        .environment(AppState())
        .frame(width: 1000, height: 700)
}


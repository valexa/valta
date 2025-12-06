//
//  TeamTab.swift
//  valta
//
//  Team tab displaying all running or pending activities in the user's team.
//  Provides visibility into what all team members are working on.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Team Stats Filter

enum TeamStatsFilter: Equatable {
    case all
    case pending
    case running
    case outcome(ActivityOutcome)
    
    var includesCompleted: Bool {
        switch self {
        case .outcome: return true
        default: return false
        }
    }
}

struct TeamTab: View {
    @Environment(TeamMemberAppState.self) private var appState
    @State private var searchText: String = ""
    @State private var statsFilter: TeamStatsFilter? = nil
    
    var filteredActivities: [Activity] {
        var activities: [Activity]
        
        // Determine base activities based on filter
        if let filter = statsFilter {
            switch filter {
            case .all:
                activities = appState.team.activities
            case .pending:
                activities = appState.teamPendingActivities
            case .running:
                activities = appState.teamRunningActivities
            case .outcome(let outcome):
                activities = appState.teamCompletedActivities.filter { $0.outcome == outcome }
            }
        } else {
            // No filter = show active activities
            activities = appState.teamActiveActivities
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            activities = activities.filter { activity in
                activity.name.localizedCaseInsensitiveContains(searchText) ||
                activity.assignedMember.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return activities
    }
    
    var groupedActivities: [(member: TeamMember, activities: [Activity])] {
        let grouped = Dictionary(grouping: filteredActivities) { $0.assignedMember.id }
        
        return appState.team.members.compactMap { member in
            guard let activities = grouped[member.id], !activities.isEmpty else { return nil }
            return (member: member, activities: activities)
        }
    }
    
    var emptyStateMessage: String {
        if let filter = statsFilter {
            switch filter {
            case .all: return "No activities in your team"
            case .pending: return "No pending activities"
            case .running: return "No running activities"
            case .outcome(let outcome): return "No \(outcome.rawValue.lowercased()) activities"
            }
        }
        return "No active activities in your team right now"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            TeamTabHeader(searchText: $searchText, statsFilter: $statsFilter)
            
            Divider()
            
            // Content
            if groupedActivities.isEmpty {
                EmptyStateView(
                    icon: AppSymbols.person3,
                    title: "No Team Activities",
                    message: emptyStateMessage,
                    iconColor: AppColors.statusRunning
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(groupedActivities, id: \.member.id) { group in
                            TeamMemberSection(member: group.member, activities: group.activities)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .searchable(text: $searchText, placement: .toolbarPrincipal, prompt: "Search activities or members...")
    }
}

// MARK: - Team Tab Header

struct TeamTabHeader: View {
    @Environment(TeamMemberAppState.self) private var appState
    @Binding var searchText: String
    @Binding var statsFilter: TeamStatsFilter?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team Activities")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text(appState.team.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Team stats (filterable)
                HStack(spacing: 12) {
                    StatButton(
                        icon: AppSymbols.person2Fill,
                        value: appState.team.activities.count,
                        label: "All",
                        color: AppColors.statTotal,
                        isSelected: statsFilter == .all,
                        action: { toggleFilter(.all) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.clock,
                        value: appState.teamPendingCount,
                        label: "Pending",
                        color: AppColors.statusTeamMemberPending,
                        isSelected: statsFilter == .pending,
                        action: { toggleFilter(.pending) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.running,
                        value: appState.teamRunningCount,
                        label: "Running",
                        color: AppColors.statusRunning,
                        isSelected: statsFilter == .running,
                        action: { toggleFilter(.running) }
                    )
                    
                    Divider()
                        .frame(height: 30)
                    
                    StatButton(
                        icon: AppSymbols.outcomeAhead,
                        value: appState.teamAheadCount,
                        label: "Ahead",
                        color: AppColors.outcomeAhead,
                        isSelected: statsFilter == .outcome(.ahead),
                        action: { toggleFilter(.outcome(.ahead)) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.outcomeJIT,
                        value: appState.teamJITCount,
                        label: "On Time",
                        color: AppColors.outcomeJIT,
                        isSelected: statsFilter == .outcome(.jit),
                        action: { toggleFilter(.outcome(.jit)) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.outcomeOverrun,
                        value: appState.teamOverrunCount,
                        label: "Overrun",
                        color: AppColors.outcomeOverrun,
                        isSelected: statsFilter == .outcome(.overrun),
                        action: { toggleFilter(.outcome(.overrun)) }
                    )
                }
            }
            
            HStack(spacing: 12) {
                Spacer()
                if statsFilter != nil {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            statsFilter = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(symbol: AppSymbols.xmark)
                                .font(.system(size: 10))
                            Text("Clear Filter")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func toggleFilter(_ filter: TeamStatsFilter) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if statsFilter == filter {
                statsFilter = nil
            } else {
                statsFilter = filter
            }
        }
    }
}

// MARK: - Team Member Section

struct TeamMemberSection: View {
    let member: TeamMember
    let activities: [Activity]
    @Environment(TeamMemberAppState.self) private var appState
    @State private var isExpanded: Bool = true
    
    var isCurrentUser: Bool {
        appState.currentMember?.id == member.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Member header
            Button(action: { withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() } }) {
                HStack(spacing: 12) {
                    MemberAvatar(member: member, size: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(member.name)
                                .font(.system(size: 15, weight: .semibold))
                            
                            if isCurrentUser {
                                Text("(You)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.accentColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text("\(activities.count) activit\(activities.count == 1 ? "y" : "ies")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(symbol: isExpanded ? AppSymbols.chevronDown : AppSymbols.chevronRight)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // Activities
            if isExpanded {
                LazyVStack(spacing: 8) {
                    ForEach(activities) { activity in
                        TeamActivityRow(activity: activity, isOwnActivity: isCurrentUser)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Team Activity Row (Uses Unified Component)

struct TeamActivityRow: View {
    let activity: Activity
    let isOwnActivity: Bool
    
    var body: some View {
        ActivityRow(
            activity: activity,
            showAssignee: false,
            isHighlighted: isOwnActivity,
            onStart: nil,
            onComplete: nil
        )
    }
}

// MARK: - Preview

#Preview {
    TeamTab()
        .environment({
            let state = TeamMemberAppState()
            state.currentMember = TeamMember.mockMembers[0]
            state.hasCompletedOnboarding = true
            return state
        }())
        .frame(width: 900, height: 700)
}


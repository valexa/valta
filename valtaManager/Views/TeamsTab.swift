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
    @State private var memberFilter: TeamMember? = nil
    
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
            
            let matchesMember = memberFilter == nil || activity.assignedMember.id == memberFilter?.id
            
            return matchesSearch && matchesStats && matchesPriority && matchesMember
        }
    }
    
    var body: some View {
        @Bindable var state = appState
        
        HSplitView {
            // Left sidebar - Team info
            TeamSidebar(statsFilter: $statsFilter, statusFilter: $statusFilter, memberFilter: $memberFilter)
                .frame(minWidth: 260, maxWidth: 320)
            
            // Main content - Activity dashboard
            VStack(spacing: 0) {
                // Header
                DashboardHeader(
                    searchText: $searchText,
                    statusFilter: $statusFilter,
                    priorityFilter: $priorityFilter,
                    statsFilter: $statsFilter,
                    memberFilter: $memberFilter
                )
                
                Divider()
                
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
            .background(Color(NSColor.controlBackgroundColor))
        }
        .sheet(isPresented: $state.showingNewActivitySheet) {
            NewActivitySheet()
        }
        .sheet(isPresented: $state.showingAddMemberSheet) {
            AddMemberSheet()
        }
    }
}

// MARK: - Team Sidebar

struct TeamSidebar: View {
    @Environment(AppState.self) private var appState
    @Binding var statsFilter: StatsFilter?
    @Binding var statusFilter: ActivityStatus?
    @Binding var memberFilter: TeamMember?
    
    var body: some View {
        VStack(spacing: 0) {
            // Team header
            VStack(alignment: .leading, spacing: 8) {
                Text(appState.team.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Stats
            StatsGrid(statsFilter: $statsFilter, statusFilter: $statusFilter)
                .padding()
            
            Divider()
            
            // Team members
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Team Members")
                        .font(.headline)
                    
                    Spacer()
                    
                    if memberFilter != nil {
                        Button(action: { 
                            withAnimation(.easeInOut(duration: 0.2)) {
                                memberFilter = nil 
                            }
                        }) {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                
                List {
                    ForEach(appState.team.members) { member in
                        MemberSelectionCard(
                            member: member,
                            isSelected: memberFilter?.id == member.id,
                            showEmail: false,
                            showActivityCounts: true,
                            runningCount: appState.team.activities.filter { $0.assignedMember.id == member.id && $0.status == .running }.count,
                            totalCount: appState.team.activities.filter { $0.assignedMember.id == member.id }.count,
                            avatarSize: 36,
                            style: .teamList,
                            action: { toggleMemberFilter(member) }
                        )
                        .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            
            Spacer()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func toggleMemberFilter(_ member: TeamMember) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if memberFilter?.id == member.id {
                memberFilter = nil
            } else {
                memberFilter = member
            }
        }
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    @Environment(AppState.self) private var appState
    @Binding var statsFilter: StatsFilter?
    @Binding var statusFilter: ActivityStatus?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Running",
                value: "\(appState.runningCount)",
                icon: "play.fill",
                color: AppColors.statusRunning,
                isSelected: statsFilter == .status(.running),
                action: { toggleFilter(.status(.running)) }
            )
            
            StatCard(
                title: "Pending",
                value: "\(appState.pendingCount)",
                icon: "clock.fill",
                color: AppColors.statusTeamMemberPending,
                isSelected: statsFilter == .pending,
                action: { toggleFilter(.pending) }
            )
            
            StatCard(
                title: "Completed",
                value: "\(appState.completedCount)",
                icon: "checkmark.circle.fill",
                color: AppColors.statusCompleted,
                isSelected: statsFilter == .status(.completed),
                action: { toggleFilter(.status(.completed)) }
            )
            
            StatCard(
                title: "Total",
                value: "\(appState.totalActivities)",
                icon: "list.bullet.rectangle",
                color: AppColors.statTotal,
                isSelected: statsFilter == nil && statusFilter == nil,
                action: { clearAllFilters() }
            )
        }
    }
    
    private func toggleFilter(_ filter: StatsFilter) {
        withAnimation(.easeInOut(duration: 0.2)) {
            // Clear dropdown filter when using stats grid
            statusFilter = nil
            
            if statsFilter == filter {
                statsFilter = nil
            } else {
                statsFilter = filter
            }
        }
    }
    
    private func clearAllFilters() {
        withAnimation(.easeInOut(duration: 0.2)) {
            statsFilter = nil
            statusFilter = nil
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var isSelected: Bool = false
    var action: (() -> Void)? = nil
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: { action?() }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 14))
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isSelected ? color.opacity(0.25) : color.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}



// MARK: - Dashboard Header

struct DashboardHeader: View {
    @Environment(AppState.self) private var appState
    @Binding var searchText: String
    @Binding var statusFilter: ActivityStatus?
    @Binding var priorityFilter: ActivityPriority?
    @Binding var statsFilter: StatsFilter?
    @Binding var memberFilter: TeamMember?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Dashboard")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    // Show member filter indicator
                    if let member = memberFilter {
                        HStack(spacing: 6) {
                            Text("Filtered by:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                MemberAvatar(member: member, size: 16)
                                Text(member.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        memberFilter = nil
                                    }
                                }) {
                                    Image(symbol: AppSymbols.xmarkCircleFill)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(12)
                        }
                    }
                }
                
                Spacer()
                
                Button(action: { appState.showingNewActivitySheet = true }) {
                    HStack(spacing: 6) {
                        Image(symbol: AppSymbols.plus)
                        Text("New Activity")
                    }
                    .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(symbol: AppSymbols.magnifyingGlass)
                        .foregroundColor(.secondary)
                    TextField("Search activities...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 280)
                
                // Status filter
                Menu {
                    Button("All Statuses") { 
                        statusFilter = nil
                        statsFilter = nil  // Clear stats filter when using dropdown
                    }
                    Divider()
                    ForEach(ActivityStatus.allCases, id: \.self) { status in
                        Button(action: { 
                            statusFilter = status
                            statsFilter = nil  // Clear stats filter when using dropdown
                        }) {
                            HStack {
                                Image(systemName: status.icon)
                                Text(status.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(symbol: AppSymbols.filter)
                        Text(statusFilter?.rawValue ?? "Status")
                        Image(symbol: AppSymbols.chevronDown)
                            .font(.caption2)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusFilter != nil ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                // Priority filter
                Menu {
                    Button("All Priorities") { priorityFilter = nil }
                    Divider()
                    ForEach(ActivityPriority.allCases, id: \.self) { priority in
                        Button(action: { priorityFilter = priority }) {
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 8, height: 8)
                                Text(priority.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(symbol: AppSymbols.flag)
                        Text(priorityFilter?.shortName ?? "Priority")
                        Image(symbol: AppSymbols.chevronDown)
                            .font(.caption2)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(priorityFilter != nil ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                // Member filter dropdown (alternative access)
                Menu {
                    Button("All Members") { memberFilter = nil }
                    Divider()
                    ForEach(appState.team.members) { member in
                        Button(action: { memberFilter = member }) {
                            HStack {
                                Text(member.initials)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(AppColors.avatar))
                                    .foregroundColor(.white)
                                Text(member.name)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                        Text(memberFilter?.name.components(separatedBy: " ").first ?? "Member")
                        Image(symbol: AppSymbols.chevronDown)
                            .font(.caption2)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(memberFilter != nil ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

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


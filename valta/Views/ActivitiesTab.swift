//
//  ActivitiesTab.swift
//  valta
//
//  Activities tab showing the current user's assigned activities.
//  Allows starting activities and requesting completion.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - My Activities Filter

enum MyActivitiesFilter: Equatable {
    case all
    case pending
    case running
    case awaiting
    case outcome(ActivityOutcome)
}

struct ActivitiesTab: View {
    @Environment(TeamMemberAppState.self) private var appState
    @State private var searchText: String = ""
    @State private var statsFilter: MyActivitiesFilter? = nil
    
    var filteredActivities: [Activity] {
        let activities: [Activity]
        
        // Determine base activities based on filter
        if let filter = statsFilter {
            switch filter {
            case .all:
                activities = appState.myActivities
            case .pending:
                activities = appState.myPendingActivities
            case .running:
                activities = appState.myRunningActivities
            case .awaiting:
                activities = appState.myAwaitingApproval
            case .outcome(let outcome):
                activities = appState.myCompletedActivities.filter { $0.outcome == outcome }
            }
        } else {
            activities = appState.myActivities
        }
        
        if searchText.isEmpty {
            return activities
        }
        
        return activities.filter { activity in
            activity.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var emptyStateMessage: String {
        if let filter = statsFilter {
            switch filter {
            case .all: return "You don't have any activities assigned yet"
            case .pending: return "No pending activities"
            case .running: return "No running activities"
            case .awaiting: return "No activities awaiting approval"
            case .outcome(let outcome): return "No \(outcome.rawValue.lowercased()) activities"
            }
        }
        return "You don't have any activities assigned yet"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ActivitiesHeader(statsFilter: $statsFilter)
            
            Divider()
            
            // Content
            if filteredActivities.isEmpty {
                EmptyStateView(
                    icon: AppSymbols.checkmarkCircle,
                    title: "No Activities",
                    message: emptyStateMessage,
                    iconColor: AppColors.success
                )
            } else if statsFilter != nil || !searchText.isEmpty {
                // Filtered view - show flat list
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredActivities) { activity in
                            ActivityRowWithSheet(activity: activity, style: styleForActivity(activity))
                        }
                    }
                    .padding()
                }
            } else {
                // Default view - show grouped sections
                ScrollView {
                    VStack(spacing: 20) {
                        // Pending activities that need to be started
                        if !appState.myPendingActivities.isEmpty {
                            ActivitySection(
                                title: "Needs Your Attention",
                                activities: appState.myPendingActivities,
                                style: .pending
                            )
                        }
                        
                        // Running activities
                        if !appState.myRunningActivities.isEmpty {
                            ActivitySection(
                                title: "In Progress",
                                activities: appState.myRunningActivities,
                                style: .running
                            )
                        }
                        
                        // Awaiting manager approval
                        if !appState.myAwaitingApproval.isEmpty {
                            ActivitySection(
                                title: "Awaiting Approval",
                                activities: appState.myAwaitingApproval,
                                style: .awaitingApproval
                            )
                        }
                        
                        // Completed activities
                        if !appState.myCompletedActivities.isEmpty {
                            ActivitySection(
                                title: "Completed",
                                activities: appState.myCompletedActivities,
                                style: .completed
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search activities...")
    }
    
    private func styleForActivity(_ activity: Activity) -> ActivitySectionStyle {
        switch activity.status {
        case .teamMemberPending: return .pending
        case .running: return .running
        case .managerPending: return .awaitingApproval
        case .completed, .canceled: return .completed
        }
    }
}

// MARK: - Activities Header

struct ActivitiesHeader: View {
    @Environment(TeamMemberAppState.self) private var appState
    @Binding var statsFilter: MyActivitiesFilter?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                // User info
                if let member = appState.currentMember {
                    HStack(spacing: 12) {
                        MemberAvatar(member: member, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
                
                Spacer()
                
                // Stats buttons (filterable)
                HStack(spacing: 12) {
                    StatButton(
                        icon: AppSymbols.trayFullFill,
                        value: appState.myActivities.count,
                        label: "All",
                        color: AppColors.statTotal,
                        isSelected: statsFilter == .all,
                        action: { toggleFilter(.all) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.clock,
                        value: appState.myPendingActivities.count,
                        label: "Pending",
                        color: AppColors.statusTeamMemberPending,
                        isSelected: statsFilter == .pending,
                        action: { toggleFilter(.pending) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.running,
                        value: appState.myRunningActivities.count,
                        label: "Running",
                        color: AppColors.statusRunning,
                        isSelected: statsFilter == .running,
                        action: { toggleFilter(.running) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.managerPending,
                        value: appState.myAwaitingApproval.count,
                        label: "Awaiting",
                        color: AppColors.statusManagerPending,
                        isSelected: statsFilter == .awaiting,
                        action: { toggleFilter(.awaiting) }
                    )
                    
                    Divider()
                        .frame(height: 30)
                    
                    StatButton(
                        icon: AppSymbols.outcomeAhead,
                        value: appState.myAheadCount,
                        label: "Ahead",
                        color: AppColors.outcomeAhead,
                        isSelected: statsFilter == .outcome(.ahead),
                        action: { toggleFilter(.outcome(.ahead)) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.outcomeJIT,
                        value: appState.myJITCount,
                        label: "On Time",
                        color: AppColors.outcomeJIT,
                        isSelected: statsFilter == .outcome(.jit),
                        action: { toggleFilter(.outcome(.jit)) }
                    )
                    
                    StatButton(
                        icon: AppSymbols.outcomeOverrun,
                        value: appState.myOverrunCount,
                        label: "Overrun",
                        color: AppColors.outcomeOverrun,
                        isSelected: statsFilter == .outcome(.overrun),
                        action: { toggleFilter(.outcome(.overrun)) }
                    )
                }
            }
            
            // Clear filter button row
            if statsFilter != nil {
                HStack {
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
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func toggleFilter(_ filter: MyActivitiesFilter) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if statsFilter == filter {
                statsFilter = nil
            } else {
                statsFilter = filter
            }
        }
    }
}

// MARK: - Activity Section

enum ActivitySectionStyle {
    case pending, running, awaitingApproval, completed
    
    var headerColor: Color {
        switch self {
        case .pending: return AppColors.statusTeamMemberPending
        case .running: return AppColors.statusRunning
        case .awaitingApproval: return AppColors.statusManagerPending  // Manager pending - red
        case .completed: return AppColors.statusCompleted
        }
    }
}

struct ActivitySection: View {
    let title: String
    let activities: [Activity]
    let style: ActivitySectionStyle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(style.headerColor)
                    .frame(width: 6, height: 6)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("(\(activities.count))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            LazyVStack(spacing: 6) {
                ForEach(activities) { activity in
                    ActivityRowWithSheet(activity: activity, style: style)
                }
            }
        }
    }
}

// MARK: - Activity Row With Sheet

struct ActivityRowWithSheet: View {
    let activity: Activity
    let style: ActivitySectionStyle
    @Environment(TeamMemberAppState.self) private var appState
    
    var body: some View {
        ActivityRow(
            activity: activity,
            showAssignee: false,
            isHighlighted: false,
            onStart: style == .pending ? { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { appState.startActivity(activity) } } : nil,
            onComplete: style == .running ? { withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { appState.requestReview(activity) } } : nil
        )
    }
}

// MARK: - Preview

#Preview {
    ActivitiesTab()
        .environment({
            let state = TeamMemberAppState()
            state.currentMember = TeamMember.mockMembers[0]
            state.hasCompletedOnboarding = true
            return state
        }())
        .frame(width: 800, height: 600)
}


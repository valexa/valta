//
//  iOSOngoingActivitiesView.swift
//  valta
//
//  iOS/iPadOS-only view displaying ongoing activities with countdown timers.
//  Simplified interface for mobile devices focused on running activities.
//  Reuses shared ActivityRow component for consistency.
//
//  Created by Antigravity on 2025-12-14.
//

import SwiftUI
// MARK: - iOS Ongoing Activities View

struct iOSOngoingActivitiesView: View {
    @Environment(TeamMemberAppState.self) private var appState
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                Group {
                    if runningAndPendingActivities.isEmpty {
                        emptyStateView
                    } else {
                        activityListView
                    }
                }
            }
            .navigationTitle("My Activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    memberInfoView
                }
            }
            .refreshable {
                await dataManager.loadData()
            }
        }
    }

    // MARK: - Computed Properties

    /// Activities that are running or pending (team member pending)
    private var runningAndPendingActivities: [Activity] {
        appState.myActivities.filter { $0.status == .running || $0.status == .teamMemberPending }
            .sorted { a, b in
                // Running activities first, then by deadline
                if a.status == .running && b.status != .running { return true }
                if a.status != .running && b.status == .running { return false }
                return a.deadline < b.deadline
            }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Active Tasks", systemImage: AppSymbols.checkmarkSeal)
        } description: {
            Text("You're all caught up! No running or pending activities.")
        }
    }

    @ViewBuilder
    private var activityListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Running activities section
                if !appState.myActivities.running.isEmpty {
                    sectionHeader("In Progress", color: AppColors.statusRunning)
                    ForEach(appState.myActivities.running) { activity in
                        iOSActivityRowWrapper(activity: activity)
                    }
                }

                // Pending activities section
                if !appState.myActivities.teamMemberPending.isEmpty {
                    sectionHeader("Needs Your Attention", color: AppColors.statusTeamMemberPending)
                    ForEach(appState.myActivities.teamMemberPending) { activity in
                        iOSActivityRowWrapper(activity: activity)
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var memberInfoView: some View {
        if let member = appState.currentMember {
            HStack(spacing: 8) {
                Text(member.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                MemberAvatar(member: member, size: 50)
            }
        }
    }

    // MARK: - Activity Row Wrapper (reuses shared ActivityRow with iOS actions)

    @ViewBuilder
    private func iOSActivityRowWrapper(activity: Activity) -> some View {
        // Use shared ActivityRow component with action callbacks
        ActivityRow(
            activity: activity,
            showAssignee: false,
            isHighlighted: false,
            onStart: activity.status == .teamMemberPending ? {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    appState.startActivity(activity)
                }
            } : nil,
            onComplete: activity.status == .running ? {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                    appState.requestReview(activity)
                }
            } : nil
        )
    }
}

// MARK: - Preview

#Preview {
    iOSOngoingActivitiesView()
        .environment({
            let state = TeamMemberAppState()
            state.currentMember = .mock
            state.hasCompletedOnboarding = true
            return state
        }())
        .environment(DataManager.shared)
}

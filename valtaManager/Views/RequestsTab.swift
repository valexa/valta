//
//  RequestsTab.swift
//  valtaManager
//
//  Requests tab for viewing and managing completion requests from team members.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct RequestsTab: View {
    @Environment(ManagerAppState.self) private var appState

    var body: some View {
        // Content
        Group {
            if appState.managerPendingActivities.isEmpty {
                EmptyRequestsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xl) {
                        ForEach(appState.managerPendingActivities) { activity in
                            RequestCard(activity: activity)
                        }
                    }
                    .padding()
                    .animation(AppAnimations.springAction, value: appState.managerPendingActivities.map(\.id))
                    .id(appState.dataVersion)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Spacer()
            }
            ToolbarItem {
                if !appState.managerPendingActivities.isEmpty {
                    ApproveAllButton {
                        withAnimation(AppAnimations.springAction) {
                            approveAll()
                        }
                    }
                }
            }
        }
    }

    private func approveAll() {
        for activity in appState.managerPendingActivities {
            appState.approveCompletion(activity)
        }
    }
}

// MARK: - Request Card

struct RequestCard: View {
    let activity: Activity
    @Environment(ManagerAppState.self) private var appState
    @State private var isHovered = false

    var body: some View {
        let outcome = activity.calculateOutcome()

        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: AppSpacing.xl) {
                // Requester avatar
                MemberAvatar(member: activity.assignedMember, size: 48)

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    // Header
                    HStack {
                        Text(activity.assignedMember.name)
                            .font(AppFont.bodyPrimary)

                        Spacer()

                        // Use completedAt or a default date
                        if let completedAt = activity.completedAt {
                            Text(completedAt.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Activity details
                    VStack(alignment: .leading) {
                        HStack(spacing: AppSpacing.sm) {
                            PriorityBadge(priority: activity.priority)

                            Text(activity.name)
                                .font(AppFont.bodyPrimaryMedium)
                        }

                        Text(activity.description)
                            .font(AppFont.bodyStandard)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)

                    // Outcome details
                    HStack(spacing: AppSpacing.sm) {
                        Text("Activity outcome:")
                            .font(AppFont.bodyStandard)
                            .foregroundColor(.secondary)

                        HStack(spacing: AppSpacing.xxs) {
                            Image(symbol: outcome.icon)
                            Text(outcome.rawValue)
                        }
                        .font(AppFont.bodyStandardSemibold)
                        .foregroundColor(outcome.color)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(outcome.color.opacity(0.15))
                        .cornerRadius(6)

                        Spacer()

                        // Deadline info
                        HStack(spacing: AppSpacing.xxs) {
                            Image(symbol: AppSymbols.calendarBadgeClock)
                                .font(AppFont.bodyStandard)
                            Text("Deadline: \(activity.deadline.formatted(date: .abbreviated, time: .shortened))")
                                .font(AppFont.bodyStandard)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(AppSpacing.xxl)

            Divider()

            // Actions
            HStack(spacing: AppSpacing.base) {
                Spacer()

                RejectButton {
                    withAnimation(AppAnimations.springAction) {
                        appState.rejectCompletion(activity)
                    }
                }

                ApproveButton {
                    withAnimation(AppAnimations.springAction) {
                        appState.approveCompletion(activity)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.vertical, AppSpacing.lg)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 6, y: 2)
        .onHover { hovering in
            withAnimation(AppAnimations.easeStandard) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Empty State

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(symbol: AppSymbols.checkmarkSeal)
                    .font(AppFont.iconXL)
                    .foregroundStyle(AppGradients.success)
            }

            Text("All Caught Up!")
                .font(AppFont.headerSection)

            Text("No pending completion requests from your team")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview("Empty") {
    RequestsTab()
        .environment(ManagerAppState())
        .frame(width: 800, height: 600)
}

#Preview("With Requests") {
    // Show RequestCards directly with mock manager-pending activities
    ScrollView {
        LazyVStack(spacing: 16) {
            RequestCard(activity: Activity.mockActivities[3])  // API Rate Limiting - managerPending
            RequestCard(activity: Activity.mockActivities[8])  // Database Migration - managerPending
        }
        .padding()
    }
    .environment(ManagerAppState())
    .frame(width: 800, height: 600)
}

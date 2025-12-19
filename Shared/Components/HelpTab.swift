//
//  HelpTab.swift
//  Shared
//
//  Help tab showing the Activity lifecycle diagram.
//  Visualizes the flow from creation to approval using existing state colors.
//
//  Created by vlad on 2025-12-18.
//

import SwiftUI

// MARK: - Help Tab

struct HelpTab: View {
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Text("Activity Lifecycle")
                .font(AppFont.headerLarge)
                .padding(.top, AppSpacing.md)

                // Main lifecycle diagram
                LifecycleDiagram()

                Text("Legend")
                    .font(AppFont.headerLarge)
                    .padding(.top, AppSpacing.md)

                HStack {
                    LifecycleLegend()
                    PrioritiesLegend()
                    OutcomesLegend()
                }
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Lifecycle Diagram

struct LifecycleDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Row 1: Manager creates → Team Member Pending
            HStack(spacing: AppSpacing.base) {
                ActorBadge(actor: "Manager", icon: "person.badge.key.fill")

                Button("Create", role: .confirm) {}
                .buttonStyle(.glass)
                .tint(AppColors.statusTeamMemberPending.opacity(0.25))

                ActionArrow(label: "creates activity")

                StateBadge(status: .teamMemberPending)
            }

            ConnectorLine()

            // Row 2: Team Member starts → Running
            HStack(spacing: AppSpacing.base) {
                ActorBadge(actor: "Team Member", icon: "person.fill")

                StartButton(action: {})

                ActionArrow(label: "starts work")

                StateBadge(status: ActivityStatus.running)
            }

            ConnectorLine()

            // Row 3: Team Member completes → Manager Pending
            HStack(spacing: AppSpacing.base) {
                ActorBadge(actor: "Team Member", icon: "person.fill")

                CompleteButton(action: {})

                ActionArrow(label: "requests review")

                StateBadge(status: .managerPending)
            }

            ConnectorLine()

            // Row 4: Manager approves/rejects
            VStack(spacing: AppSpacing.xl) {
                HStack(alignment: .top, spacing: AppSpacing.huge) {
                    ActorBadge(actor: "Manager", icon: "person.badge.key.fill")
                    // Approve path
                    VStack(spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(symbol: AppSymbols.completed)
                                .foregroundColor(AppColors.statusCompleted)
                            Text("Approve")
                                .font(AppFont.bodyStandardSemibold)
                                .foregroundColor(AppColors.statusCompleted)
                        }

                        Image(symbol: AppSymbols.arrowDown)
                            .foregroundColor(.secondary)

                        StateBadge(status: .completed)
                    }

                    // Reject path
                    VStack(spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(symbol: AppSymbols.arrowUturnBackward)
                                .foregroundColor(AppColors.statusRunning)
                            Text("Reject")
                                .font(AppFont.bodyStandardSemibold)
                                .foregroundColor(AppColors.statusRunning)
                        }

                        Image(symbol: AppSymbols.arrowDown)
                            .foregroundColor(.secondary)

                        StateBadge(status: .running)
                    }
                }
            }
        }
        .padding(AppSpacing.xxl)
    }
}

// MARK: - State Badge (Diagram)

struct StateBadge: View {
    let status: ActivityStatus

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: status.icon)
                .font(AppFont.bodySmall)
            Text(status.rawValue)
                .font(AppFont.bodySmallSemibold)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.sm)
        .background(status.color.opacity(0.15))
        .cornerRadius(AppCornerRadius.md)
    }
}

// MARK: - Actor Badge

struct ActorBadge: View {
    let actor: String
    let icon: String

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(AppFont.bodyLarge)
                .foregroundColor(.secondary)
            Text(actor)
                .font(AppFont.captionMedium)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
}

// MARK: - Action Arrow

struct ActionArrow: View {
    let label: String

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(symbol: AppSymbols.arrowRight)
                .foregroundColor(.secondary)
            Text(label)
                .font(AppFont.caption)
                .foregroundColor(.secondary)
            Image(symbol: AppSymbols.arrowRight)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Connector Line

struct ConnectorLine: View {
    var body: some View {
        Image(symbol: AppSymbols.arrowTurn)
            .padding(.leading)
    }
}

// MARK: - Lifecycle Legend

struct LifecycleLegend: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Activity Statuses")
                .font(AppFont.bodyPrimary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 220))
            ], spacing: 12) {
                LegendItem(
                    color: AppColors.statusTeamMemberPending,
                    icon: AppSymbols.teamMemberPending,
                    title: "Team Member Pending",
                    description: "Assigned but not started"
                )

                LegendItem(
                    color: AppColors.statusRunning,
                    icon: AppSymbols.running,
                    title: "Running",
                    description: "Work in progress"
                )

                LegendItem(
                    color: AppColors.statusManagerPending,
                    icon: AppSymbols.managerPending,
                    title: "Manager Pending",
                    description: "Awaiting manager review"
                )

                LegendItem(
                    color: AppColors.statusCompleted,
                    icon: AppSymbols.completed,
                    title: "Completed",
                    description: "Approved by manager"
                )

                LegendItem(
                    color: AppColors.statusCanceled,
                    icon: AppSymbols.canceled,
                    title: "Canceled",
                    description: "Activity was canceled"
                )
            }
        }
        .padding(AppSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Outcomes Legend

struct OutcomesLegend: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Completion Outcomes")
                .font(AppFont.bodyPrimary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 220))
            ], spacing: 12) {
                LegendItem(
                    color: AppColors.outcomeAhead,
                    icon: AppSymbols.outcomeAhead,
                    title: "Ahead",
                    description: "Completed before deadline"
                )

                LegendItem(
                    color: AppColors.outcomeJIT,
                    icon: AppSymbols.outcomeJIT,
                    title: "Just In Time",
                    description: "Completed within 5 min of deadline"
                )

                LegendItem(
                    color: AppColors.outcomeOverrun,
                    icon: AppSymbols.outcomeOverrun,
                    title: "Overrun",
                    description: "Completed after deadline"
                )
            }
        }
        .padding(AppSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Priorities Legend

struct PrioritiesLegend: View {
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Priority Levels")
                .font(AppFont.bodyPrimary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 160, maximum: 220))
            ], spacing: 12) {
                LegendItem(
                    color: AppColors.priorityP0,
                    icon: AppSymbols.flagFill,
                    title: "P0 - Critical",
                    description: "Urgent, requires immediate action"
                )

                LegendItem(
                    color: AppColors.priorityP1,
                    icon: AppSymbols.flag,
                    title: "P1 - High",
                    description: "Important, needs attention soon"
                )

                LegendItem(
                    color: AppColors.priorityP2,
                    icon: AppSymbols.flag,
                    title: "P2 - Medium",
                    description: "Normal priority work"
                )

                LegendItem(
                    color: AppColors.priorityP3,
                    icon: AppSymbols.flagSlash,
                    title: "P3 - Low",
                    description: "Can wait, background tasks"
                )
            }
        }
        .padding(AppSpacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: icon)
                        .font(AppFont.caption)
                    Text(title)
                        .font(AppFont.badge)
                }
                .foregroundColor(color)

                Text(description)
                    .font(AppFont.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    HelpTab()
        .frame(width: 700, height: 800)
}

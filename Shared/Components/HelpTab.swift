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
            VStack {
                Text("Activity Lifecycle")
                .font(AppFont.headerLarge)
                .padding(.top, 10)

                // Main lifecycle diagram
                LifecycleDiagram()
                    .padding(.horizontal)

                // Legend
                LifecycleLegend()
                    .padding(.horizontal)

                // Outcomes
                OutcomesLegend()
                    .padding(.horizontal)

                // Priorities
                PrioritiesLegend()
                    .padding(.horizontal)

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Lifecycle Diagram

struct LifecycleDiagram: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: Manager creates → Team Member Pending
            HStack(spacing: 12) {
                ActorBadge(actor: "Manager", icon: "person.badge.key.fill")

                Button("Create", role: .confirm) {}
                .buttonStyle(.glass)
                .tint(AppColors.statusTeamMemberPending.opacity(0.25))

                ActionArrow(label: "creates activity")

                StateBadge(status: .teamMemberPending)
            }

            ConnectorLine()

            // Row 2: Team Member starts → Running
            HStack(spacing: 12) {
                ActorBadge(actor: "Team Member", icon: "person.fill")

                CompletionButton(action: {
                }) {
                    HStack(spacing: 3) {
                        Image(symbol: AppSymbols.play)
                            .font(AppFont.caption)
                        Text("Start")
                            .font(AppFont.captionSemibold)
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.glassProminent)
                .tint(AppColors.statusRunning.opacity(0.25))

                ActionArrow(label: "starts work")

                StateBadge(status: ActivityStatus.running)
            }

            ConnectorLine()

            // Row 3: Team Member completes → Manager Pending
            HStack(spacing: 12) {
                ActorBadge(actor: "Team Member", icon: "person.fill")

                CompletionButton(action: {
                }) {
                    HStack(spacing: 3) {
                        Image(symbol: AppSymbols.checkmark)
                            .font(AppFont.captionBold)
                        Text("Complete")
                            .font(AppFont.captionSemibold)
                    }
                    .foregroundColor(.white)
                }
                .buttonStyle(.glassProminent)
                .tint(AppColors.statusManagerPending.opacity(0.25))

                ActionArrow(label: "requests review")

                StateBadge(status: .managerPending)
            }

            ConnectorLine()

            // Row 4: Manager approves/rejects
            VStack(spacing: 16) {
                HStack(spacing: 40) {
                    ActorBadge(actor: "Manager", icon: "person.badge.key.fill")
                        .padding(.bottom)
                    // Approve path
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
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
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
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
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: AppColors.shadow.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - State Badge (Diagram)

struct StateBadge: View {
    let status: ActivityStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(AppFont.bodySmall)
            Text(status.rawValue)
                .font(AppFont.bodySmallSemibold)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(status.color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Actor Badge

struct ActorBadge: View {
    let actor: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
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
        HStack(spacing: 4) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 100, height: 2)
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

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

// MARK: - Lifecycle Legend

struct LifecycleLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status Reference")
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

// MARK: - Outcomes Legend

struct OutcomesLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

// MARK: - Priorities Legend

struct PrioritiesLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
        )
    }
}

// MARK: - Legend Item

struct LegendItem: View {
    let color: Color
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
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

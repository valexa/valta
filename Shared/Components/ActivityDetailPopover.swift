//
//  ActivityDetailPopover.swift
//  Shared
//
//  Context menu content showing activity details, dates, and running time.
//
//  Created by vlad on 2025-12-15.
//

import SwiftUI

// MARK: - Activity Detail Context Menu

/// Context menu content for ActivityRow showing all activity details and dates
struct ActivityDetailContextMenu: View {
    let activity: Activity

    var body: some View {
        Group {
            // Dates Section
            Section("Timeline") {
                Label {
                    Text("Created: \(activity.createdAt.formatted(date: .abbreviated, time: .shortened))")
                } icon: {
                    Image(symbol: AppSymbols.calendar)
                }

                Label {
                    Text("Deadline: \(activity.deadline.formatted(date: .abbreviated, time: .shortened))")
                } icon: {
                    Image(symbol: AppSymbols.clock)
                }

                if let startedAt = activity.startedAt {
                    Label {
                        Text("Started: \(startedAt.formatted(date: .abbreviated, time: .shortened))")
                    } icon: {
                        Image(symbol: AppSymbols.play)
                    }
                }

                if let completedAt = activity.completedAt {
                    Label {
                        Text("Completed: \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                    } icon: {
                        Image(symbol: AppSymbols.checkmark)
                    }
                }
            }

            Divider()

            Section("Durations") {
                Label {
                    Text("\(statusDurationLabel): \(activity.timeCalculator.currentStatusDurationFormatted)")
                } icon: {
                    Image(symbol: AppSymbols.timer)
                }

                // Outcome projection for non-completed activities
                if activity.status != .completed && activity.status != .canceled {
                    let projectedOutcome = activity.calculateOutcome(completionDate: Date())
                    Label {
                        Text("If completed now: \(projectedOutcome.rawValue)")
                    } icon: {
                        Image(symbol: projectedOutcome.icon)
                    }
                }
            }
        }
    }

    private var statusDurationLabel: String {
        switch activity.status {
        case .teamMemberPending:
            return "Waiting"
        case .running:
            return "Running"
        case .managerPending:
            return "Awaiting Approval"
        case .completed:
            return "Total Time"
        case .canceled:
            return "Duration"
        }
    }
}

// MARK: - Preview

#Preview("Context Menu Demo") {
    VStack(spacing: 8) {
        Text("Right-click any row for context menu")
            .font(.caption)
            .foregroundColor(.secondary)

        // Running activity
        ActivityRow(activity: .mock, showAssignee: true)
            .contextMenu {
                ActivityDetailContextMenu(activity: .mock)
            }

        // Pending activity
        ActivityRow(activity: Activity.mockActivities[2])
            .contextMenu {
                ActivityDetailContextMenu(activity: Activity.mockActivities[2])
            }

        // Completed activity
        ActivityRow(activity: Activity.mockActivities[4])
            .contextMenu {
                ActivityDetailContextMenu(activity: Activity.mockActivities[4])
            }
    }
    .padding()
    .frame(width: 600, height: 300)
}

#Preview("Menu Content") {
    VStack {
        ActivityDetailContextMenu(activity: .mock)
    }
    .padding()
    .frame(width: 300, height: 400)
}

//
//  ActivityRow.swift
//  Shared
//
//  Unified activity row component used across all tabs in both apps.
//  Displays activity details, status, time remaining/delta, and optional actions.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Activity Row

/// Unified activity row component used across all tabs in both apps
struct ActivityRow: View {
    @Environment(\.theme) private var theme

    let activity: Activity
    var showAssignee: Bool = false
    var isHighlighted: Bool = false
    var onStart: (() -> Void)?
    var onComplete: (() -> Void)?

    @State private var isHovered = false

    var body: some View {

        HStack(spacing: 10) {
            // Priority badge
            PriorityBadge(priority: activity.priority, compact: true)

            // Activity name
            Text(activity.name)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .frame(minWidth: 100, alignment: .leading)

            // Assignee (optional)
            if showAssignee {
                HStack(spacing: 4) {
                    MemberAvatar(member: activity.assignedMember, size: 20)
                    Text(activity.assignedMember.name.components(separatedBy: " ").first ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 80, alignment: .leading)
            }

            Spacer()

            // Time remaining with progress bar (for non-completed activities)
            if activity.status != .completed && activity.status != .canceled {
                TimeRemainingLabel(activity: activity, compact: true, showProgressBar: true)
            }

            // Overdue indicator
            if activity.isOverdue {
                Image(symbol: AppSymbols.exclamationTriangle)
                    .foregroundColor(theme.destructive)
                    .font(.system(size: 11))
            }

            // Time delta for completed activities (shows how much ahead/overrun)
            if activity.status == .completed {
                CompletionTimeDelta(activity: activity)
            }

            // Status/Outcome badge
            if activity.status == .completed, let outcome = activity.outcome {
                OutcomeBadge(outcome: outcome)
            } else {
                StatusBadge(
                    status: activity.status,
                    outcome: activity.outcome,
                    displayColor: activity.displayColor(using: theme),
                    compact: true
                )
            }

            // Action buttons (visible on hover, only if actions are available)
            // Show processing state regardless of hover if processing
            if isHovered && hasAvailableActions {
                actionButtons
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHighlighted ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    /// Check if there are any actions that can be shown
    private var hasAvailableActions: Bool {
        (activity.status == .teamMemberPending && onStart != nil) ||
        (activity.status == .running && onComplete != nil)
    }

    @ViewBuilder
    var actionButtons: some View {
        HStack(spacing: 6) {
            if activity.status == .teamMemberPending, let onStart = onStart {
                CompletionButton(action: {
                    onStart()
                }) {
                    HStack(spacing: 3) {
                        Image(symbol: AppSymbols.play)
                            .font(.system(size: 9))
                        Text("Start")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.color(for: .running).gradient)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }

            if activity.status == .running, let onComplete = onComplete {
                CompletionButton(action: {
                    onComplete()
                }) {
                    HStack(spacing: 3) {
                        Image(symbol: AppSymbols.checkmark)
                            .font(.system(size: 9))
                        Text("Done")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.successGradient)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Completion Time Delta

/// Shows how much time ahead or overrun the activity was completed
struct CompletionTimeDelta: View {
    let activity: Activity

    private var deltaText: String {
        activity.timeCalculator.completionDeltaFormatted ?? "-"
    }

    var body: some View {
        Text(deltaText)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        // Running activity
        ActivityRow(
            activity: .mock,
            showAssignee: true
        )

        // Pending activity
        ActivityRow(
            activity: Activity.mockActivities[2]
        )

        // Completed activity (ahead)
        ActivityRow(
            activity: Activity.mockActivities[4]
        )

        // Completed activity (JIT)
        ActivityRow(
            activity: Activity.mockActivities[9]
        )

        // Completed activity (overrun)
        ActivityRow(
            activity: Activity.mockActivities[10]
        )
    }
    .padding()
    .frame(width: 700)
}

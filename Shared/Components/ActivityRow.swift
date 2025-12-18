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
import TipKit

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
    private let activityRowTip = ActivityRowTip()

    var body: some View {

        HStack(spacing: 10) {
            // Priority badge
            PriorityBadge(priority: activity.priority)

            // Activity name
            Text(activity.name)
                .font(AppFont.bodyStandardMedium)
                .lineLimit(1)
                .frame(minWidth: 100, alignment: .leading)

            // Assignee (optional)
            if showAssignee {
                HStack(spacing: 4) {
                    MemberAvatar(member: activity.assignedMember, size: 20)
                    Text(activity.assignedMember.name.components(separatedBy: " ").first ?? "")
                        .font(AppFont.caption)
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
                    .font(AppFont.caption)
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
            // Animate presence with smooth spring transition
            if isHovered && hasAvailableActions {
                actionButtons
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.92)).animation(.spring(response: 0.25, dampingFraction: 0.8)),
                        removal: .opacity.animation(.easeOut(duration: 0.15))
                    ))
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .contextMenu {
            ActivityDetailContextMenu(activity: activity)
        }
        .help(activity.description)
        .popoverTip(activityRowTip, arrowEdge: .bottom)
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
                StartButton(action: onStart)
            }

            if activity.status == .running, let onComplete = onComplete {
                CompleteButton(action: onComplete)
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
            .font(AppFont.captionMonospaced)
            .foregroundColor(.secondary)
    }
}

// MARK: - Preview

#Preview("States") {
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

#Preview("Action Buttons") {
    VStack(spacing: 12) {
        // Pending activity with Start button - hover to see
        Text("Hover to see action buttons:")
            .font(.caption)
            .foregroundColor(.secondary)

        ActivityRow(
            activity: Activity.mockActivities[2], // teamMemberPending
            onStart: { print("Start tapped") }
        )

        ActivityRow(
            activity: .mock, // running
            onComplete: { print("Done tapped") }
        )
    }
    .padding()
    .frame(width: 700)
}

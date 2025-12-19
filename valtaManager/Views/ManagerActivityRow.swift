//
//  ManagerActivityRow.swift
//  valtaManager
//
//  Card component displaying an activity with its details, status, and actions.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct ManagerActivityRow: View {
    let activity: Activity
    @Environment(ManagerAppState.self) private var appState
    @State private var isHovered = false
    @State private var showingCompleteSheet = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            HStack(alignment: .top, spacing: AppSpacing.xl) {
                // Priority indicator
                VStack {
                    PriorityBadge(priority: activity.priority)

                    // Overdue indicator (only for active activities)
                    if activity.isOverdue && activity.status != .completed && activity.status != .canceled {
                        Image(symbol: AppSymbols.exclamationTriangle)
                            .foregroundColor(AppColors.destructive)
                            .font(AppFont.bodyStandard)
                            .padding(.top, AppSpacing.xxs)
                    }
                }

                // Activity info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text(activity.name)
                            .font(AppFont.bodyPrimary)
                            .lineLimit(1)

                        Spacer()

                        StatusBadge(status: activity.status, outcome: activity.outcome, displayColor: activity.displayColor)
                    }

                    Text(activity.description)
                        .font(AppFont.bodyStandard)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)

                    HStack(spacing: AppSpacing.xl) {
                        // Assignee
                        HStack(spacing: AppSpacing.xs) {
                            MemberAvatar(member: activity.assignedMember, size: 22)

                            Text(activity.assignedMember.name)
                                .font(AppFont.bodyStandard)
                                .foregroundColor(.secondary)
                        }

                        // Deadline with progress bar (only for active activities)
                        if activity.status != .completed && activity.status != .canceled {
                            TimeRemainingLabel(activity: activity, compact: false, showProgressBar: true)
                        }

                        // Created date
                        HStack(spacing: AppSpacing.xxs) {
                            Image(symbol: AppSymbols.calendar)
                                .font(AppFont.caption)
                            Text(activity.deadline.formatted(date: .abbreviated, time: .shortened))
                                .font(AppFont.bodyStandard)
                        }
                        .foregroundColor(.secondary)

                        Spacer()
                    }
                }

                // Actions
                if isHovered && activity.status != .completed && activity.status != .canceled {
                    HStack(spacing: AppSpacing.sm) {
                        if activity.status == .running || activity.status == .managerPending {
                            Button(action: { showingCompleteSheet = true }) {
                                Image(symbol: AppSymbols.checkmark)
                                    .font(AppFont.bodyStandardSemibold)
                            }
                            .buttonStyle(.glass)
                            .foregroundColor(AppColors.success)
                            .help("Complete Activity")
                        }

                        Button(action: { appState.cancelActivity(activity) }) {
                            Image(symbol: AppSymbols.xmark)
                                .font(AppFont.bodyStandardSemibold)
                        }
                        .buttonStyle(.glass)
                        .foregroundColor(AppColors.destructive)
                        .help("Cancel Activity")
                    }
                }
            }
            .padding(AppSpacing.xl)

            // Outcome indicator for completed activities
            if activity.status == .completed, let outcome = activity.outcome {
                Divider()

                HStack(spacing: AppSpacing.sm) {
                    Image(symbol: outcome.icon)
                        .font(AppFont.bodyStandard)

                    Text("Completed \(outcome.rawValue)")
                        .font(AppFont.bodyStandardMedium)

                    if let completedAt = activity.completedAt {
                        Text("•")
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(AppFont.bodyStandard)
                    }

                    Spacer()
                }
                .foregroundColor(outcome.color)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.md)
                .background(outcome.color.opacity(0.1))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(AppCornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(color: AppColors.shadow.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4, y: 2)
        .onHover { hovering in
            withAnimation(AppAnimations.easeStandard) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(AppAnimations.easeStandard) {
                isExpanded.toggle()
            }
        }
        .sheet(isPresented: $showingCompleteSheet) {
            CompleteActivitySheet(activity: activity)
        }
    }
}

struct CompleteActivitySheet: View {
    let activity: Activity
    @Environment(ManagerAppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.xxxl) {
            // Header
            VStack(spacing: AppSpacing.sm) {
                Image(symbol: AppSymbols.checkmarkSeal)
                    .font(AppFont.iconXL)
                    .foregroundStyle(AppGradients.success)

                Text("Complete Activity")
                    .font(AppFont.headerSection)

                Text(activity.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Info
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("Are you sure you want to complete this activity?")
                    .font(.headline)

                Text("The outcome will be automatically determined based on the deadline.")
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Actions
            HStack(spacing: AppSpacing.base) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button("Complete") {
                    appState.completeActivity(activity)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(AppSpacing.xxxl)
        .frame(width: 400, height: 320)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ManagerActivityRow(activity: .mock)
        ManagerActivityRow(activity: Activity.mockActivities[4])
    }
    .padding()
    .environment(ManagerAppState())
}

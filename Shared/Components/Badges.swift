//
//  Badges.swift
//  Shared
//
//  Reusable badge components for displaying status, priority, and outcome.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Priority Badge

struct PriorityBadge: View {
    @Environment(\.theme) private var theme

    let priority: ActivityPriority

    var body: some View {
        Text(priority.shortName)
            .font(AppFont.priorityBadge)
            .foregroundColor(.white)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, AppSpacing.xs)
            .background(priority.color(using: theme).gradient)
            .cornerRadius(AppCornerRadius.xs)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: ActivityStatus
    let outcome: ActivityOutcome?
    let displayColor: Color
    var compact: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(symbol: status.icon)
            .font(AppFont.caption)

            Text(status.rawValue)
            .font(compact ? AppFont.badgeCompact : AppFont.badge)
        }
        .foregroundColor(displayColor)
        .padding(.horizontal, compact ? AppSpacing.xs : AppSpacing.sm)
        .padding(.vertical, compact ? AppSpacing.xxxs : AppSpacing.xxs)
        .background(displayColor.opacity(0.15))
        .cornerRadius(compact ? AppCornerRadius.xs : AppCornerRadius.sm)
    }
}

// MARK: - Outcome Badge

struct OutcomeBadge: View {
    @Environment(\.theme) private var theme

    let outcome: ActivityOutcome

    private var color: Color {
        outcome.color(using: theme)
    }

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(symbol: outcome.icon)
            .font(AppFont.caption)

            Text(outcome.rawValue)
            .font(AppFont.badge)
        }
        .foregroundColor(color)
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xxs)
        .background(color.opacity(0.15))
        .cornerRadius(AppCornerRadius.sm)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            PriorityBadge(priority: .p0)
            PriorityBadge(priority: .p1)
            PriorityBadge(priority: .p2)
            PriorityBadge(priority: .p3)
        }

        HStack(spacing: 12) {
            StatusBadge(status: .running, outcome: nil, displayColor: .blue)
            StatusBadge(status: .completed, outcome: .ahead, displayColor: .green)
        }

        HStack(spacing: 12) {
            StatusBadge(status: .managerPending, outcome: nil, displayColor: AppColors.statusManagerPending)
            StatusBadge(status: .teamMemberPending, outcome: nil, displayColor: AppColors.statusTeamMemberPending)
        }

        HStack(spacing: 12) {
            OutcomeBadge(outcome: .ahead)
            OutcomeBadge(outcome: .jit)
            OutcomeBadge(outcome: .overrun)
        }
    }
    .padding()
}

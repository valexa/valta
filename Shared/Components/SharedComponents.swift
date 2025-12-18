//
//  SharedComponents.swift
//  Shared
//
//  Reusable UI components shared between valtaManager and valta apps.
//  Includes badges, avatars, and common card elements.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Member Avatar

struct MemberAvatar: View {
    @Environment(\.theme) private var theme

    let member: TeamMember?
    var size: CGFloat = 36
    var initialsOverride: String?

    private var displayInitials: String {
        if let override = initialsOverride {
            return override
        }
        return member?.initials ?? "?"
    }

    var body: some View {
        Button(action: {}) {
            Text(displayInitials)
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .tint(.brown)
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .allowsHitTesting(false)
    }

    /// Convenience initializer for member-based avatar
    init(member: TeamMember, size: CGFloat = 36) {
        self.member = member
        self.size = size
        self.initialsOverride = nil
    }

    /// Convenience initializer for preview avatar with custom initials
    init(initials: String, size: CGFloat = 36) {
        self.member = nil
        self.size = size
        self.initialsOverride = initials
    }
}

// MARK: - Time Remaining Label

struct TimeRemainingLabel: View {
    @Environment(\.theme) private var theme

    let activity: Activity
    var compact: Bool = false
    var showProgressBar: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(symbol: AppSymbols.clock)
                    .font(AppFont.caption)
                Text(activity.timeRemaining)
                    .font(activity.isOverdue ? AppFont.bodyStandardSemibold : AppFont.bodySmall)
            }
            .foregroundColor(activity.isOverdue ? theme.destructive : .secondary)

            if showProgressBar && activity.status != .completed && activity.status != .canceled {
                TimeProgressBar(activity: activity, height: compact ? 3 : 4, width: compact ? 40 : 50)
            }
        }
    }
}

// MARK: - Time Progress Bar

struct TimeProgressBar: View {
    @Environment(\.theme) private var theme

    let activity: Activity
    var height: CGFloat = 4
    var width: CGFloat = 60

    private var progressColor: Color {
        let remaining = activity.timeRemainingProgress
        if remaining <= 0 || activity.isOverdue {
            return theme.destructive
        } else if remaining < 0.25 {
            return theme.warning  // Orange - urgent
        } else if remaining < 0.5 {
            return theme.color(for: .jit)  // Yellow - caution
        } else {
            return theme.success  // Green - good
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.2))

                // Progress fill
                Capsule()
                    .fill(progressColor.gradient)
                    .frame(width: max(geometry.size.width * activity.timeRemainingProgress, 0))
            }
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Activity Info Row

struct ActivityInfoRow: View {
    let icon: String
    let text: String
    var color: Color = .secondary

    var body: some View {
        HStack(spacing: 4) {
            Image(symbol: icon)
                .font(AppFont.caption)
            Text(text)
                .font(AppFont.bodyStandard)
        }
        .foregroundColor(color)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var iconColor: Color = .secondary

    var body: some View {
        VStack(spacing: 16) {
            Image(symbol: icon)
                .font(AppFont.iconXL)
                .foregroundColor(iconColor)

            Text(title)
                .font(AppFont.headerSectionSemibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    var title: String = "Something went wrong"
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(symbol: AppSymbols.exclamationTriangle)
                .font(AppFont.iconXL)
                .foregroundColor(AppColors.destructive)
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(message)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Retry", action: onRetry)
                .buttonStyle(.glassProminent)
        }
        .padding()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.white)
            Text(message)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var count: Int?

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.bodyStandardSemibold)
                .foregroundColor(.secondary)

            if let count = count {
                Text("(\(count))")
                    .font(AppFont.bodyStandard)
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Previews

#Preview("Components") {
    VStack(spacing: 20) {
        // MemberAvatar
        HStack(spacing: 12) {
            MemberAvatar(member: .mock)
            MemberAvatar(member: .mock, size: 72)
            MemberAvatar(initials: "VA", size: 36)
                .disabled(true)
        }

        Divider()

        // TimeRemainingLabel & TimeProgressBar
        VStack(alignment: .leading, spacing: 8) {
            Text("TimeRemainingLabel").font(.caption).foregroundColor(.secondary)
            TimeRemainingLabel(activity: .mock, showProgressBar: true)
            TimeRemainingLabel(activity: .mock, compact: true, showProgressBar: true)
        }

        Divider()

        // ActivityInfoRow
        VStack(alignment: .leading, spacing: 8) {
            Text("ActivityInfoRow").font(.caption).foregroundColor(.secondary)
            ActivityInfoRow(icon: AppSymbols.clock, text: "2 hours remaining")
            ActivityInfoRow(icon: AppSymbols.allActivities, text: "Assigned to John", color: .blue)
        }

        Divider()

        // EmptyStateView
        VStack(alignment: .leading, spacing: 8) {
            Text("EmptyStateView").font(.caption).foregroundColor(.secondary)
            EmptyStateView(
                icon: AppSymbols.tray,
                title: "No Activities",
                message: "You have no pending activities."
            )
            .frame(height: 150)
        }

        Divider()

        // SectionHeader
        VStack(alignment: .leading, spacing: 8) {
            Text("SectionHeader").font(.caption).foregroundColor(.secondary)
            SectionHeader(title: "Pending", count: 5)
            SectionHeader(title: "Completed")
        }
    }
    .padding()
    .frame(width: 400)
}

#Preview("LoadingView") {
    ZStack {
        AppGradients.teamMemberBackground.ignoresSafeArea()
        LoadingView(message: "Loading Teams...")
    }
    .frame(width: 400, height: 300)
}

#Preview("ErrorView") {
    ZStack {
        AppGradients.managerBackground.ignoresSafeArea()
        ErrorView(title: "Error loading teams", message: "Failed to connect to server.") {}
    }
    .frame(width: 400, height: 300)
}

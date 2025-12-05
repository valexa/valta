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
    var initialsOverride: String? = nil
    
    private var displayInitials: String {
        if let override = initialsOverride {
            return override
        }
        return member?.initials ?? "?"
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(theme.avatarGradient)
                .frame(width: size, height: size)
            
            Text(displayInitials)
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
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
    
    /// Observes refresh timer for automatic updates
    private var refreshTick: UInt64 {
        RefreshTimer.shared.tick
    }
    
    var body: some View {
        HStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(symbol: AppSymbols.clock)
                    .font(.system(size: compact ? 10 : 11))
                Text(activity.timeRemaining)
                    .font(.system(size: compact ? 11 : 12, weight: activity.isOverdue ? .semibold : .regular))
            }
            .foregroundColor(activity.isOverdue ? theme.destructive : .secondary)
            
            if showProgressBar && activity.status != .completed && activity.status != .canceled {
                TimeProgressBar(activity: activity, height: compact ? 3 : 4, width: compact ? 40 : 50)
            }
        }
        .id(refreshTick) // Force refresh when timer ticks
    }
}

// MARK: - Time Progress Bar

struct TimeProgressBar: View {
    @Environment(\.theme) private var theme
    
    let activity: Activity
    var height: CGFloat = 4
    var width: CGFloat = 60
    
    /// Observes refresh timer for automatic updates
    private var refreshTick: UInt64 {
        RefreshTimer.shared.tick
    }
    
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
        .id(refreshTick) // Force refresh when timer ticks
    }
}

// MARK: - Activity Info Row

struct ActivityInfoRow: View {
    let icon: String
    let text: String
    var color: Color = .secondary
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12))
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
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
            
            if let count = count {
                Text("(\(count))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
            MemberAvatar(member: TeamMember.mockMembers[0])
            MemberAvatar(member: TeamMember.mockMembers[1], size: 48)
        }
        
        HStack(spacing: 12) {
            OutcomeBadge(outcome: .ahead)
            OutcomeBadge(outcome: .jit)
            OutcomeBadge(outcome: .overrun)
        }
    }
    .padding()
}


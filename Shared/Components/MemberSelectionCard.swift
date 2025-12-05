//
//  MemberSelectionCard.swift
//  Shared
//
//  Unified member selection/display card component used across all apps.
//  Supports multiple display modes: onboarding selection, team list, and filter selection.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

/// Unified member selection/display card component
/// Supports multiple display modes: onboarding selection, team list, and filter selection
struct MemberSelectionCard: View {
    let member: TeamMember
    var isSelected: Bool = false
    var showEmail: Bool = true
    var showActivityCounts: Bool = false
    var runningCount: Int = 0
    var totalCount: Int = 0
    var avatarSize: CGFloat = 40
    var style: CardStyle = .onboarding
    var action: (() -> Void)? = nil
    
    @State private var isHovered = false
    
    enum CardStyle {
        case onboarding      // Onboarding flow style (dark background, light borders)
        case teamList        // Team list style (manager app sidebar)
        case teamMemberOnboarding  // Team member onboarding style (teal theme)
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                // Avatar with selection indicator
                ZStack(alignment: .bottomTrailing) {
                    MemberAvatar(member: member, size: avatarSize)
                    
                    // Selection indicator (for team list style)
                    if style == .teamList && isSelected {
                        Image(symbol: AppSymbols.checkmarkCircleFill)
                            .font(.system(size: avatarSize * 0.35))
                            .foregroundColor(.accentColor)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: avatarSize * 0.3, height: avatarSize * 0.3)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
                
                // Member info
                VStack(alignment: .leading, spacing: 2) {
                    Text(member.name)
                        .font(.system(size: nameSize, weight: nameFontWeight))
                        .foregroundColor(nameColor)
                    
                    if showEmail {
                        Text(member.email)
                            .font(.system(size: emailSize))
                            .foregroundColor(emailColor)
                            .lineLimit(1)
                    }
                    
                    if showActivityCounts {
                        HStack(spacing: 4) {
                            Text("\(runningCount) running")
                                .foregroundColor(runningCount > 0 ? AppColors.statusRunning : .secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("\(totalCount) total")
                                .foregroundColor(.secondary)
                        }
                        .font(.caption2)
                    }
                }
                
                Spacer()
                
                // Selection indicator (circle with checkmark)
                selectionIndicator
            }
            .padding(paddingValue)
            .background(backgroundView)
            .overlay(borderView)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
    
    // MARK: - Computed Properties for Styling
    
    private var nameSize: CGFloat {
        switch style {
        case .onboarding: return 14
        case .teamList: return 13
        case .teamMemberOnboarding: return 14
        }
    }
    
    private var nameFontWeight: Font.Weight {
        isSelected ? .semibold : .medium
    }
    
    private var nameColor: Color {
        switch style {
        case .onboarding, .teamMemberOnboarding:
            return .white
        case .teamList:
            return isSelected ? .accentColor : .primary
        }
    }
    
    private var emailSize: CGFloat {
        11
    }
    
    private var emailColor: Color {
        switch style {
        case .onboarding, .teamMemberOnboarding:
            return .white.opacity(0.5)
        case .teamList:
            return .secondary
        }
    }
    
    private var paddingValue: EdgeInsets {
        switch style {
        case .onboarding:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .teamList:
            return EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        case .teamMemberOnboarding:
            return EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .onboarding:
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        case .teamList:
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : (isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear))
        case .teamMemberOnboarding:
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.05)))
        }
    }
    
    @ViewBuilder
    private var borderView: some View {
        switch style {
        case .onboarding:
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? AppColors.success.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        case .teamList:
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        case .teamMemberOnboarding:
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? AppColors.TeamMember.selectionStart.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
        }
    }
    
    @ViewBuilder
    private var selectionIndicator: some View {
        ZStack {
            Circle()
                .stroke(selectionIndicatorStrokeColor, lineWidth: 2)
                .frame(width: selectionIndicatorSize, height: selectionIndicatorSize)
            
            if isSelected {
                Circle()
                    .fill(selectionIndicatorFillGradient)
                    .frame(width: selectionIndicatorSize, height: selectionIndicatorSize)
                
                Image(symbol: AppSymbols.checkmark)
                    .font(.system(size: selectionIndicatorSize * 0.5, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var selectionIndicatorSize: CGFloat {
        switch style {
        case .onboarding: return 24
        case .teamList: return 0 // Not used in team list
        case .teamMemberOnboarding: return 22
        }
    }
    
    private var selectionIndicatorStrokeColor: Color {
        switch style {
        case .onboarding, .teamMemberOnboarding:
            return isSelected ? Color.clear : Color.white.opacity(0.3)
        case .teamList:
            return Color.clear // Not used
        }
    }
    
    private var selectionIndicatorFillGradient: AnyShapeStyle {
        switch style {
        case .onboarding:
            return AnyShapeStyle(AppColors.success)
        case .teamList:
            return AnyShapeStyle(Color.clear) // Not used
        case .teamMemberOnboarding:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AppColors.TeamMember.selectionStart, AppColors.TeamMember.selectionEnd],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Preview

#Preview("Onboarding Style") {
    VStack(spacing: 12) {
        MemberSelectionCard(
            member: TeamMember.mockMembers[0],
            isSelected: false,
            style: .onboarding,
            action: {}
        )
        
        MemberSelectionCard(
            member: TeamMember.mockMembers[1],
            isSelected: true,
            style: .onboarding,
            action: {}
        )
    }
    .padding()
    .background(AppGradients.managerBackground)
}

#Preview("Team List Style") {
    VStack(spacing: 8) {
        MemberSelectionCard(
            member: TeamMember.mockMembers[0],
            isSelected: false,
            showEmail: false,
            showActivityCounts: true,
            runningCount: 2,
            totalCount: 5,
            avatarSize: 36,
            style: .teamList,
            action: {}
        )
        
        MemberSelectionCard(
            member: TeamMember.mockMembers[1],
            isSelected: true,
            showEmail: false,
            showActivityCounts: true,
            runningCount: 0,
            totalCount: 3,
            avatarSize: 36,
            style: .teamList,
            action: {}
        )
    }
    .padding()
}

#Preview("Team Member Onboarding Style") {
    VStack(spacing: 12) {
        MemberSelectionCard(
            member: TeamMember.mockMembers[0],
            isSelected: false,
            avatarSize: 44,
            style: .teamMemberOnboarding,
            action: {}
        )
        
        MemberSelectionCard(
            member: TeamMember.mockMembers[1],
            isSelected: true,
            avatarSize: 44,
            style: .teamMemberOnboarding,
            action: {}
        )
    }
    .padding()
    .background(AppGradients.teamMemberBackground)
}

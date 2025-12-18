//
//  MemberSelectionCard.swift
//  Shared
//
//  Member selection card component for onboarding flows.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

/// Member selection card component for onboarding flows
struct MemberSelectionCard: View {
    let member: TeamMember
    var isSelected: Bool = false
    var isDisabled: Bool = false
    var avatarSize: CGFloat = 44
    var action: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            button
            CheckmarkButton(isSelected: isSelected, placeholder: false)
        }
    }

    var button: some View {
        Button(action: { action?() }) {
            HStack(spacing: AppSpacing.base) {
                MemberAvatar(member: member, size: avatarSize)
                    .padding(.leading)
                info
            }
            .frame(width: 220, height: 60, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.12) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.05)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
#if os(macOS)
        .disabled(isDisabled)
        .blur(radius: isDisabled ? 1.0 : 0.0)
#endif
        .onHover { hovering in
            withAnimation(AppAnimations.easeQuick) {
                isHovered = hovering
            }
        }
    }

    var info: some View {
        // Member info
        VStack(alignment: .leading, spacing: AppSpacing.xxxs) {
            Text(member.name)
                .font(isSelected ? AppFont.bodyStandardSemibold : AppFont.bodyStandardMedium)
                .foregroundColor(.white)
                .lineLimit(2)
            Text(member.email)
                .font(AppFont.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            // Show "Logged in elsewhere" for disabled members
            if isDisabled {
                Text("Logged in elsewhere")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.trailing)
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
        MemberSelectionCard(
            member: TeamMember.mockMembers[0],
            isSelected: false
        )
        MemberSelectionCard(
            member: TeamMember.mockMembers[1],
            isSelected: true
        )
        MemberSelectionCard(
            member: TeamMember.mockMembers[2],
            isSelected: false,
            isDisabled: true
        )
    }
    .frame(maxWidth: 600)
}

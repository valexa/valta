//
//  MemberAvatar.swift
//  Shared
//
//  Created by vlad on 2026-01-24.
//

import SwiftUI

struct MemberAvatar: View {
    @Environment(\.theme) private var theme

    let member: TeamMember?
    var size: CGFloat = 36

    var body: some View {
        Button(action: {}) {
            Text(member?.initials ?? "?")
                .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .frame(width: size, height: size)
        .tint(theme.avatar)
        .buttonStyle(.glass)
        .buttonBorderShape(.capsule)
        .allowsHitTesting(false)
    }

    /// Convenience initializer for member-based avatar
    init(member: TeamMember, size: CGFloat = appTheme.avatarSize) {
        self.member = member
        self.size = size
    }

}

public struct MemberAvatarColored: View {
    let member: TeamMember?
    var size: CGFloat = 36
    var badge: String?
    var badgeAlignment: Alignment = .bottom

    private var displayInitials: String {
        return member?.initials ?? "?"
    }

    private var deterministicGradient: RadialGradient {
        let chars = Array(displayInitials)
        let c1 = chars.first ?? "?"
        let c2 = chars.count > 1 ? chars[1] : c1

        let color1 = Color.from(character: c1)
        let color2 = Color.from(character: c2)

        let baseColor = color1.mix(with: color2)
        let firstColor = Color.white.mix(with: baseColor)

        return RadialGradient(
            colors: [firstColor, baseColor],
            center: UnitPoint(x: 0.3, y: 0),
            startRadius: 0,
            endRadius: size / 1.5
        )
    }

    public var body: some View {
        Text(displayInitials)
            .font(.system(size: size * 0.36, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
            .frame(width: size, height: size / 2)
            .background(deterministicGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.xl))
            .glassEffect(in: RoundedRectangle(cornerRadius: AppCornerRadius.xl))
            .overlay(alignment: badgeAlignment) {
                if let badge = badge, !badge.isEmpty {
                    Text(badge)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .font(AppFont.bodyStandard)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .background(AppColors.frame.opacity(0.8))
                        .cornerRadius(AppCornerRadius.xs)
                        .offset(x: 8, y: -8)
                }
            }
    }

    /// Convenience initializer for member-based avatar
    init(
        member: TeamMember,
        size: CGFloat = 36,
        badge: String? = nil,
        badgeAlignment: Alignment = .topTrailing
    ) {
        self.member = member
        self.size = size
        self.badge = badge
        self.badgeAlignment = badgeAlignment
    }
}

// MARK: - Previews

#Preview("MemberAvatar") {
    HStack(spacing: 20) {
        MemberAvatar(member: .mock, size: 28)
        MemberAvatar(member: .mock, size: 48)
        MemberAvatar(member: .mock, size: 88)
    }
    .padding()
}

#Preview("MemberAvatarColored") {
    HStack {
        VStack {
            MemberAvatarColored(member: TeamMember(id: UUID(), name: "VA", email: ""), size: 25, badge: "25")
            MemberAvatarColored(member: TeamMember(id: UUID(), name: "VA", email: ""), size: 33, badge: "33")
            MemberAvatarColored(member: TeamMember(id: UUID(), name: "VA", email: ""), size: 50, badge: "50")
            MemberAvatarColored(member: TeamMember(id: UUID(), name: "VA", email: ""), size: 75, badge: "75")
            MemberAvatarColored(member: TeamMember(id: UUID(), name: "VA", email: ""), size: 100, badge: "100")

        }
        VStack {
            MemberAvatarColored(member: .mock, size: 25, badge: "25")
            MemberAvatarColored(member: .mock, size: 33, badge: "33")
            MemberAvatarColored(member: .mock, size: 50, badge: "50")
            MemberAvatarColored(member: .mock, size: 75, badge: "75")
            MemberAvatarColored(member: .mock, size: 100, badge: "100")

        }
    }
    .padding()
}

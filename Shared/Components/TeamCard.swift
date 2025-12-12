//
//  TeamCard.swift
//  valta
//
//  A reusable card component for displaying team information with selection state.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct TeamCard: View {
    let team: Team
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(symbol: AppSymbols.person3)
                        .font(.system(size: 24))
                VStack(alignment: .leading, spacing: 4) {
                    Text(team.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(team.members.count) members")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }

                // Member preview avatars
                HStack(spacing: -4) {
                    ForEach(Array(team.members.prefix(10))) { member in
                        MemberAvatar(member: member, size: 36)
                    }
                    if team.members.count > 10 {
                        Text("+\(team.members.count - 10)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.leading, 12)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                CheckmarkButton(isSelected: isSelected)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(.regularMaterial))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppColors.TeamMember.primary : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

// MARK: - Preview

#Preview {
    TeamCard(team: .mock, isSelected: false) {}
}

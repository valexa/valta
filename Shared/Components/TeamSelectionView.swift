//
//  TeamSelectionView.swift
//  Shared
//
//  Reusable team selection grid component used in onboarding flows.
//  Displays available teams as cards in an adaptive grid layout.
//
//  Created by vlad on 2025-12-11.
//

import SwiftUI

struct TeamSelectionView: View {
    @Environment(DataManager.self) private var dataManager
    @Binding var selectedTeam: Team?

    private let columns = [GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 20)]

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                ForEach(dataManager.teams) { team in
                    TeamCard(
                        team: team,
                        isSelected: selectedTeam?.id == team.id
                    ) {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedTeam = team
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollClipDisabled()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedTeam: Team?

    TeamSelectionView(selectedTeam: $selectedTeam)
        .environment(DataManager.shared)
        .frame(width: 600, height: 400)
        .background(AppGradients.teamMemberBackground)
}

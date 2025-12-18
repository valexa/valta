//
//  StatButton.swift
//  Shared
//
//  Reusable stat button component for filtering activity lists.
//  Used in both My Activities and Team Activities tabs.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Stat Button

/// A tappable stat button that can be used to filter activity lists
struct StatButton: View {
    let icon: String
    let value: Int
    let label: String
    var color: Color = .accentColor
    var isSelected: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(symbol: icon)
                    .font(.system(size: AppFontSize.bodyStandard))
                    .foregroundColor(isSelected ? .white : color)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(value)")
                        .font(AppFont.statMedium)
                        .foregroundColor(isSelected ? .white : color)

                    Text(label)
                        .font(.system(size: AppFontSize.caption))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

#Preview("All States") {
    VStack(spacing: 16) {
        // Unselected states
        Text("Unselected").font(.caption).foregroundColor(.secondary)
        HStack(spacing: 12) {
            StatButton(
                icon: AppSymbols.trayFullFill,
                value: 10,
                label: "All",
                color: AppColors.statTotal,
                isSelected: false
            ) {}

            StatButton(
                icon: AppSymbols.clock,
                value: 3,
                label: "Pending",
                color: AppColors.statusTeamMemberPending,
                isSelected: false
            ) {}

            StatButton(
                icon: AppSymbols.running,
                value: 5,
                label: "Running",
                color: AppColors.statusRunning,
                isSelected: false
            ) {}
        }

        // Selected states
        Text("Selected").font(.caption).foregroundColor(.secondary)
        HStack(spacing: 12) {
            StatButton(
                icon: AppSymbols.trayFullFill,
                value: 10,
                label: "All",
                color: AppColors.statTotal,
                isSelected: true
            ) {}

            StatButton(
                icon: AppSymbols.clock,
                value: 3,
                label: "Pending",
                color: AppColors.statusTeamMemberPending,
                isSelected: true
            ) {}

            StatButton(
                icon: AppSymbols.running,
                value: 5,
                label: "Running",
                color: AppColors.statusRunning,
                isSelected: true
            ) {}
        }

        // Outcome colors
        Text("Outcomes").font(.caption).foregroundColor(.secondary)
        HStack(spacing: 12) {
            StatButton(
                icon: AppSymbols.outcomeAhead,
                value: 2,
                label: "Ahead",
                color: AppColors.outcomeAhead,
                isSelected: false
            ) {}

            StatButton(
                icon: AppSymbols.outcomeJIT,
                value: 1,
                label: "JIT",
                color: AppColors.outcomeJIT,
                isSelected: true
            ) {}

            StatButton(
                icon: AppSymbols.outcomeOverrun,
                value: 4,
                label: "Overrun",
                color: AppColors.outcomeOverrun,
                isSelected: false
            ) {}
        }
    }
    .padding()
}

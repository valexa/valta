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
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : color)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(value)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : color)
                    
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
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

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        StatButton(
            icon: AppSymbols.clock,
            value: 3,
            label: "Pending",
            color: AppColors.statusTeamMemberPending,
            isSelected: false,
            action: {}
        )
        
        StatButton(
            icon: AppSymbols.running,
            value: 5,
            label: "Running",
            color: AppColors.statusRunning,
            isSelected: true,
            action: {}
        )
        
        StatButton(
            icon: AppSymbols.outcomeAhead,
            value: 2,
            label: "Ahead",
            color: AppColors.outcomeAhead,
            isSelected: false,
            action: {}
        )
    }
    .padding()
}


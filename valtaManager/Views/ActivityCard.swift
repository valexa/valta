//
//  ActivityCard.swift
//  valtaManager
//
//  Card component displaying an activity with its details, status, and actions.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct ActivityCard: View {
    let activity: Activity
    @Environment(AppState.self) private var appState
    @State private var isHovered = false
    @State private var showingCompleteSheet = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            HStack(alignment: .top, spacing: 16) {
                // Priority indicator
                VStack {
                    PriorityBadge(priority: activity.priority)
                    
                    if activity.isOverdue {
                        Image(symbol: AppSymbols.exclamationTriangle)
                            .foregroundColor(AppColors.destructive)
                            .font(.system(size: 14))
                            .padding(.top, 4)
                    }
                }
                
                // Activity info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(activity.name)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        StatusBadge(status: activity.status, outcome: activity.outcome, displayColor: activity.displayColor)
                    }
                    
                    Text(activity.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    HStack(spacing: 16) {
                        // Assignee
                        HStack(spacing: 6) {
                            MemberAvatar(member: activity.assignedMember, size: 22)
                            
                            Text(activity.assignedMember.name)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        // Deadline with progress bar
                        TimeRemainingLabel(activity: activity, compact: false, showProgressBar: true)
                        
                        // Created date
                        HStack(spacing: 4) {
                            Image(symbol: AppSymbols.calendar)
                                .font(.system(size: 11))
                            Text(activity.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                // Actions
                if isHovered && activity.status != .completed && activity.status != .canceled {
                    HStack(spacing: 8) {
                        if activity.status == .running || activity.status == .managerPending {
                            Button(action: { showingCompleteSheet = true }) {
                                Image(symbol: AppSymbols.checkmarkCircle)
                                    .font(.system(size: 18))
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(AppColors.success)
                            .help("Complete Activity")
                        }
                        
                        Button(action: { appState.cancelActivity(activity) }) {
                            Image(symbol: AppSymbols.xmarkCircle)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(AppColors.destructive)
                        .help("Cancel Activity")
                    }
                }
            }
            .padding(16)
            
            // Outcome indicator for completed activities
            if activity.status == .completed, let outcome = activity.outcome {
                Divider()
                
                HStack(spacing: 8) {
                    Image(systemName: outcome.icon)
                        .font(.system(size: 12))
                    
                    Text("Completed \(outcome.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                    
                    if let completedAt = activity.completedAt {
                        Text("•")
                        Text(completedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 12))
                    }
                    
                    Spacer()
                }
                .foregroundColor(outcome.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(outcome.color.opacity(0.1))
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(color: AppColors.shadow.opacity(isHovered ? 0.1 : 0.05), radius: isHovered ? 8 : 4, y: 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }
        .sheet(isPresented: $showingCompleteSheet) {
            CompleteActivitySheet(activity: activity)
        }
    }
}

// MARK: - Complete Activity Sheet

struct CompleteActivitySheet: View {
    let activity: Activity
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOutcome: ActivityOutcome = .jit
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                Image(symbol: AppSymbols.checkmarkSeal)
                    .font(.system(size: 48))
                    .foregroundStyle(AppGradients.success)
                
                Text("Complete Activity")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                Text(activity.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Outcome selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Outcome")
                    .font(.headline)
                
                ForEach(ActivityOutcome.allCases, id: \.self) { outcome in
                    OutcomeOption(
                        outcome: outcome,
                        isSelected: selectedOutcome == outcome,
                        action: { selectedOutcome = outcome }
                    )
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                
                Button("Complete") {
                    appState.completeActivity(activity, outcome: selectedOutcome)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 400, height: 420)
    }
}

struct OutcomeOption: View {
    let outcome: ActivityOutcome
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: outcome.icon)
                    .font(.system(size: 20))
                    .foregroundColor(outcome.color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(outcome.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(outcomeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(symbol: AppSymbols.checkmarkCircleFill)
                        .foregroundColor(.accentColor)
                        .font(.system(size: 20))
                }
            }
            .padding(12)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    var outcomeDescription: String {
        switch outcome {
        case .ahead: return "Completed more than 30 minutes before deadline"
        case .jit: return "Completed within 5 minutes of deadline"
        case .overrun: return "Completed after the deadline"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ActivityCard(activity: Activity.mockActivities[0])
        ActivityCard(activity: Activity.mockActivities[4])
    }
    .padding()
    .environment(AppState())
}


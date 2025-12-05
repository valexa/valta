//
//  LogTab.swift
//  valta
//
//  Log tab providing a history of activity events.
//  Shows when activities were started, completion requested, completed, or canceled.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct LogTab: View {
    @Environment(TeamMemberAppState.self) private var appState
    @State private var searchText: String = ""
    @State private var statusFilter: ActivityStatus? = nil
    @State private var priorityFilter: ActivityPriority? = nil
    @State private var outcomeFilter: ActivityOutcome? = nil
    @State private var showOnlyMine: Bool = false
    
    var filteredEntries: [ActivityLogEntry] {
        var entries = appState.activityLog
        
        // Filter by "mine"
        if showOnlyMine, let member = appState.currentMember {
            entries = entries.filter { $0.activity.assignedMember.id == member.id }
        }
        
        // Filter by status
        if let status = statusFilter {
            entries = entries.filter { $0.activity.status == status }
        }
        
        // Filter by priority
        if let priority = priorityFilter {
            entries = entries.filter { $0.activity.priority == priority }
        }
        
        // Filter by outcome
        if let outcome = outcomeFilter {
            entries = entries.filter { $0.activity.outcome == outcome }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.activity.name.localizedCaseInsensitiveContains(searchText) ||
                entry.activity.assignedMember.name.localizedCaseInsensitiveContains(searchText) ||
                entry.performedBy.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return entries
    }
    
    var groupedEntries: [(date: String, entries: [ActivityLogEntry])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            formatter.string(from: entry.timestamp)
        }
        
        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { first, second in
                let firstDate = first.entries.first?.timestamp ?? Date.distantPast
                let secondDate = second.entries.first?.timestamp ?? Date.distantPast
                return firstDate > secondDate
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            LogTabHeader(
                searchText: $searchText,
                statusFilter: $statusFilter,
                priorityFilter: $priorityFilter,
                outcomeFilter: $outcomeFilter,
                showOnlyMine: $showOnlyMine
            )
            
            Divider()
            
            // Content
            if filteredEntries.isEmpty {
                EmptyStateView(
                    icon: "list.bullet.clipboard",
                    title: "No Log Entries",
                    message: showOnlyMine ? "You haven't had any activity yet" : "No activity log entries match your filter",
                    iconColor: .secondary
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(groupedEntries, id: \.date) { group in
                            LogDateSection(date: group.date, entries: group.entries)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Log Tab Header

struct LogTabHeader: View {
    @Environment(TeamMemberAppState.self) private var appState
    @Binding var searchText: String
    @Binding var statusFilter: ActivityStatus?
    @Binding var priorityFilter: ActivityPriority?
    @Binding var outcomeFilter: ActivityOutcome?
    @Binding var showOnlyMine: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Activity Log")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("\(appState.activityLog.count) entries")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // All/My Activities toggle
                Picker("", selection: $showOnlyMine) {
                    Text("All Activities").tag(false)
                    Text("My Activities").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(symbol: AppSymbols.magnifyingGlass)
                        .foregroundColor(.secondary)
                    TextField("Search log...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 200)
                
                // Status filter
                Menu {
                    Button("All Statuses") { statusFilter = nil }
                    Divider()
                    ForEach(ActivityStatus.allCases, id: \.self) { status in
                        Button(action: { statusFilter = status }) {
                            HStack {
                                Image(systemName: status.icon)
                                Text(status.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(symbol: AppSymbols.filter)
                        Text(statusFilter?.rawValue ?? "Status")
                        Image(symbol: AppSymbols.chevronDown)
                            .font(.caption2)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusFilter != nil ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                // Priority filter
                Menu {
                    Button("All Priorities") { priorityFilter = nil }
                    Divider()
                    ForEach(ActivityPriority.allCases, id: \.self) { priority in
                        Button(action: { priorityFilter = priority }) {
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 8, height: 8)
                                Text(priority.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(symbol: AppSymbols.flag)
                        Text(priorityFilter?.shortName ?? "Priority")
                        Image(symbol: AppSymbols.chevronDown)
                            .font(.caption2)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(priorityFilter != nil ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                // Outcome filter
                Menu {
                    Button("All Outcomes") { outcomeFilter = nil }
                    Divider()
                    ForEach(ActivityOutcome.allCases, id: \.self) { outcome in
                        Button(action: { outcomeFilter = outcome }) {
                            HStack {
                                Image(systemName: outcome.icon)
                                Text(outcome.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: AppSymbols.outcomeAhead)
                        Text(outcomeFilter?.rawValue ?? "Outcome")
                        Image(symbol: AppSymbols.chevronDown)
                            .font(.caption2)
                    }
                    .font(.system(size: 12))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(outcomeFilter != nil ? Color.accentColor.opacity(0.15) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
                
                // Clear filters button
                if statusFilter != nil || priorityFilter != nil || outcomeFilter != nil {
                    Button(action: {
                        statusFilter = nil
                        priorityFilter = nil
                        outcomeFilter = nil
                    }) {
                        Text("Clear")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Log Date Section

struct LogDateSection: View {
    let date: String
    let entries: [ActivityLogEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(date)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
            }
            
            // Entries
            LazyVStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    LogEntryRow(entry: entry, isLast: index == entries.count - 1)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: ActivityLogEntry
    let isLast: Bool
    @Environment(TeamMemberAppState.self) private var appState
    @State private var isHovered = false
    
    var isOwnActivity: Bool {
        appState.currentMember?.id == entry.activity.assignedMember.id
    }
    
    var actionIcon: String {
        switch entry.action {
        case .created: return "plus.circle.fill"
        case .started: return "play.circle.fill"
        case .completionRequested: return "paperplane.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        }
    }
    
    var actionColor: Color {
        switch entry.action {
        case .created: return AppColors.statusTeamMemberPending
        case .started: return AppColors.statusRunning
        case .completionRequested: return AppColors.statusManagerPending
        case .completed: return AppColors.statusCompleted
        case .canceled: return AppColors.statusCanceled
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Timeline indicator
                VStack(spacing: 0) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 20))
                        .foregroundColor(actionColor)
                    
                    if !isLast {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Action description
                    HStack(spacing: 8) {
                        Text(entry.action.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(actionColor)
                        
                        Text("by \(entry.performedBy)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Activity details
                    HStack(spacing: 10) {
                        PriorityBadge(priority: entry.activity.priority, compact: true)
                        
                        Text(entry.activity.name)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Member info
                        HStack(spacing: 6) {
                            MemberAvatar(member: entry.activity.assignedMember, size: 20)
                            
                            Text(entry.activity.assignedMember.name)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            if isOwnActivity {
                                Text("(You)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .padding(10)
                    .background(isOwnActivity ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Outcome for completed entries
                    if entry.action == .completed, let outcome = entry.activity.outcome {
                        HStack(spacing: 6) {
                            Image(systemName: outcome.icon)
                                .font(.system(size: 11))
                            Text("Outcome: \(outcome.rawValue)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(outcome.color)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .background(isHovered ? Color.accentColor.opacity(0.03) : Color.clear)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            
            if !isLast {
                Divider()
                    .padding(.leading, 52)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    LogTab()
        .environment({
            let state = TeamMemberAppState()
            state.currentMember = TeamMember.mockMembers[0]
            state.hasCompletedOnboarding = true
            return state
        }())
        .frame(width: 900, height: 700)
}


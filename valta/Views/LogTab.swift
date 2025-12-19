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
    @State private var statusFilter: ActivityStatus?
    @State private var priorityFilter: ActivityPriority?
    @State private var outcomeFilter: ActivityOutcome?
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
            // Content
            if filteredEntries.isEmpty {
                EmptyStateView(
                    icon: AppSymbols.listBulletClipboard,
                    title: "No Log Entries",
                    message: showOnlyMine ? "You haven't had any activity yet" : "No activity log entries match your filter",
                    iconColor: .secondary
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xxxl) {
                        ForEach(groupedEntries, id: \.date) { group in
                            LogDateSection(date: group.date, entries: group.entries)
                        }
                    }
                    .padding()
                    .id(appState.dataVersion)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .searchable(text: $searchText, placement: .toolbarPrincipal, prompt: "Search log...")
        .toolbar {

            // Filters
            ToolbarItemGroup(placement: .navigation) {
                // All/My Activities
                Picker("", selection: $showOnlyMine) {
                    Text("All").tag(false)
                    Text("Mine").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }

            ToolbarItem(placement: .automatic) {
                // Status Filter
                StatusFilterMenu(selection: $statusFilter)
            }

            ToolbarItem(placement: .automatic) {
                // Priority Filter
                PriorityFilterMenu(selection: $priorityFilter)
            }

            ToolbarItem(placement: .automatic) {
                // Outcome Filter
                OutcomeFilterMenu(selection: $outcomeFilter)
            }
            ToolbarItem(placement: .automatic) {
                // Clear
                if statusFilter != nil || priorityFilter != nil || outcomeFilter != nil {
                    Button(action: {
                        withAnimation {
                            statusFilter = nil
                            priorityFilter = nil
                            outcomeFilter = nil
                        }
                    }) {
                        Image(symbol: AppSymbols.xmarkCircleFill)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Log Date Section

struct LogDateSection: View {
    let date: String
    let entries: [ActivityLogEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            // Date header
            HStack {
                Text(date)
                    .font(AppFont.bodyStandardSemibold)
                    .foregroundColor(.secondary)

                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 1)
            }

            // Entries
            LazyVStack(spacing: 0) {
                ForEach(entries) { entry in
                    LogEntryRow(entry: entry)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(AppCornerRadius.lg)
        }
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: ActivityLogEntry
    @Environment(TeamMemberAppState.self) private var appState
    @State private var isHovered = false

    var isOwnActivity: Bool {
        appState.currentMember?.id == entry.activity.assignedMember.id
    }

    var actionIcon: String {
        switch entry.action {
        case .created: return AppSymbols.plusCircleFill
        case .started: return AppSymbols.running
        case .completionRequested: return AppSymbols.paperplaneCircleFill
        case .completed: return AppSymbols.completed
        case .canceled: return AppSymbols.canceled
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
        HStack(alignment: .center, spacing: AppSpacing.base) {
            // Timeline indicator
            Image(symbol: actionIcon)
                .font(AppFont.bodyLarge)
                .foregroundColor(actionColor.opacity(0.5))
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                // Action description
                HStack(spacing: AppSpacing.xs) {
                    Text(entry.action.rawValue)
                        .font(AppFont.bodyStandardSemibold)
                        .foregroundColor(actionColor.opacity(0.5))

                    Text("by \(entry.performedBy)")
                        .font(AppFont.bodyStandard)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                }

                // Activity details
                HStack(spacing: AppSpacing.sm) {
                    PriorityBadge(priority: entry.activity.priority)

                    Text(entry.activity.name)
                        .font(AppFont.bodyStandardMedium)
                        .lineLimit(1)

                    Spacer()

                    // Member info
                    HStack(spacing: AppSpacing.xxs) {
                        MemberAvatar(member: entry.activity.assignedMember, size: 22)

                        Text(entry.activity.assignedMember.name)
                            .font(AppFont.caption)
                            .foregroundColor(.secondary)

                        if isOwnActivity {
                            Text("(You)")
                                .font(AppFont.caption)
                                .foregroundColor(.accentColor)
                        }
                    }

                    // Outcome for completed entries
                    if entry.action == .completed, let outcome = entry.activity.outcome {
                        HStack(spacing: AppSpacing.xxs) {
                            Image(symbol: outcome.icon)
                            .font(AppFont.caption)
                            Text(outcome.rawValue)
                                .font(AppFont.caption)
                        }
                        .foregroundColor(outcome.color)
                    }
                }
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.sm)
        .background(isHovered ? Color.accentColor.opacity(0.03) : Color.clear)
        .onHover { hovering in
            withAnimation(AppAnimations.easeQuick) {
                isHovered = hovering
            }
        }
        .contextMenu {
            ActivityDetailContextMenu(activity: entry.activity)
        }
        .help(entry.activity.description)
    }
}

// MARK: - Preview

#Preview {
    LogTab()
        .environment({
            let state = TeamMemberAppState()
            state.currentMember = .mock
            state.hasCompletedOnboarding = true
            return state
        }())
        .frame(width: 900, height: 700)
}

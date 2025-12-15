//
//  NewActivitySheet.swift
//  valtaManager
//
//  Sheet for creating a new activity with all required fields.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct NewActivitySheet: View {
    @Environment(ManagerAppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var selectedMember: TeamMember?
    @State private var priority: ActivityPriority = .p2
    @State private var deadline: Date = Date().addingTimeInterval(3600 * 4) // 4 hours from now

    private var isValid: Bool {
        !name.isEmpty && !description.isEmpty && selectedMember != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel", role: .destructive) {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Text("New Activity")
                    .font(.system(size: 16, weight: .semibold))

                Spacer()

                Button("Create", role: .confirm) {
                    createActivity()
                }
                .buttonStyle(.glass)
                .tint(.green)
                .disabled(!isValid)
            }
            .padding()

            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Deadline section
                    HStack {
                        DatePicker(
                            "",
                            selection: $deadline,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.field)
                        .labelsHidden()

                        // Quick deadline buttons
                        HStack(spacing: 8) {
                            QuickDeadlineButton(label: "1h") { deadline = Date().addingTimeInterval(3600) }
                            QuickDeadlineButton(label: "4h") { deadline = Date().addingTimeInterval(3600 * 4) }
                            QuickDeadlineButton(label: "1d") { deadline = Date().addingTimeInterval(86400) }
                            QuickDeadlineButton(label: "3d") { deadline = Date().addingTimeInterval(86400 * 3) }
                            QuickDeadlineButton(label: "1w") { deadline = Date().addingTimeInterval(86400 * 7) }
                        }
                    }

                    // Assigned member
                    memberSelectionView

                    // Activity name
                    TextField("Activity name", text: $name)
                        .focusEffectDisabled()
                        .onChange(of: name) { _, newValue in
                            let sanitized = newValue.sanitizedForCSV
                            if sanitized != newValue {
                                name = sanitized
                            }
                        }
                    // Description
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Activity description")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 8)
                        }

                        TextEditor(text: $description)
                            .font(.body)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)
                            .onChange(of: description) { _, newValue in
                                let sanitized = newValue.sanitizedForCSV
                                if sanitized != newValue {
                                    description = sanitized
                                }
                            }
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )

                    // Priority
                    HStack(spacing: 8) {
                        ForEach(ActivityPriority.allCases, id: \.self) { p in
                            PriorityOption(
                                priority: p,
                                isSelected: priority == p
                            ) { priority = p }
                        }
                    }
                    .frame(height: 40)
                }
            }
            .padding(.all)

            Divider()

            // Preview
            if isValid {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    NotificationPreview(
                        activityName: name,
                        priority: priority,
                        deadline: deadline,
                        memberName: selectedMember?.name ?? ""
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(width: 520, height: 520)
    }

    private func createActivity() {
        guard let member = selectedMember else { return }

        let activity = Activity(
            name: name,
            description: description,
            assignedMember: member,
            priority: priority,
            status: .teamMemberPending,
            deadline: deadline
        )

        appState.addActivity(activity)
        dismiss()
    }

    private var memberSelectionView: some View {
        Menu {
            ForEach(appState.team.members) { member in
                Button(action: { selectedMember = member }) {
                    HStack {
                        Text(member.name)
                        if selectedMember?.id == member.id {
                            Image(symbol: AppSymbols.checkmark)
                        }
                    }
                }
            }
        } label: {
            HStack {
                if let member = selectedMember {
                    HStack(spacing: 8) {
                        MemberAvatar(member: member, size: 44)
                        Text(member.name)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("Team member")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Priority Option

struct PriorityOption: View {
    let priority: ActivityPriority
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(priority.shortName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))

                Text(priorityLabel)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .white : priority.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .background(isSelected ? priority.color : priority.color.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(priority.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var priorityLabel: String {
        switch priority {
        case .p0: return "Critical"
        case .p1: return "High"
        case .p2: return "Medium"
        case .p3: return "Low"
        }
    }
}

// MARK: - Quick Deadline Button

struct QuickDeadlineButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Notification Preview

struct NotificationPreview: View {
    let activityName: String
    let priority: ActivityPriority
    let deadline: Date
    let memberName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(symbol: AppSymbols.bellBadge)
                .font(.system(size: 24))
                .foregroundColor(AppColors.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notification to \(memberName)")
                    .font(.system(size: 12, weight: .semibold))

                Text("[Manager name] has assigned \(priority.shortName) activity on \(Date().formatted(date: .abbreviated, time: .shortened)) with deadline \(deadline.formatted(date: .abbreviated, time: .shortened)) to you, please start the activity: \(activityName)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.warning.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    NewActivitySheet()
        .environment(ManagerAppState())
}

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

    private let maxNameLength = 200
    private let maxDescriptionLength = 500

    private var nameError: String {
        name.count > maxNameLength ? "Maximum \(maxNameLength) characters (\(name.count)/\(maxNameLength))" : ""
    }

    private var descriptionError: String {
        description.count > maxDescriptionLength ? "Maximum \(maxDescriptionLength) characters (\(description.count)/\(maxDescriptionLength))" : ""
    }

    private var isValid: Bool {
        !name.isEmpty && !description.isEmpty && selectedMember != nil && nameError.isEmpty && descriptionError.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel", role: .destructive) {
                    dismiss()
                }
                .buttonStyle(.glass)
                Spacer()

                Text("New Activity")
                    .font(AppFont.buttonLarge)

                Spacer()

                Button("Create", role: .confirm) {
                    createActivity()
                }
                .buttonStyle(.glass)
                .tint(AppColors.statusTeamMemberPending.opacity(0.25))
                .disabled(!isValid)
            }
            .padding()

            // Form
            ScrollView {
                VStack(alignment: .center, spacing: 16) {

                    // Assigned member
                    memberSelectionView

                    // Deadline section
                    dateSelectionView

                    // Activity name
                    FloatingTextField(title: "Activity name", text: $name, error: nameError)
                        .onChange(of: name) { _, newValue in
                            let sanitized = newValue.sanitizedForCSV
                            if sanitized != newValue {
                                name = sanitized
                            }
                        }

                    // Description
                    FloatingTextField(title: "Activity description", text: $description, error: descriptionError, isMultiline: true, minHeight: 100)
                        .onChange(of: description) { _, newValue in
                            let sanitized = newValue.sanitizedForCSV
                            if sanitized != newValue {
                                description = sanitized
                            }
                        }

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
        .frame(width: 520, height: 550)
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

    private var dateSelectionView: some View {
        VStack {
            DatePicker(
                "",
                selection: $deadline,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .tint(.red)
            .labelsHidden()
            .datePickerStyle(.compact)

            // Quick deadline buttons
            HStack(spacing: 8) {
                QuickDeadlineButton(label: "1h") { deadline = Date().addingTimeInterval(3600) }
                QuickDeadlineButton(label: "4h") { deadline = Date().addingTimeInterval(3600 * 4) }
                QuickDeadlineButton(label: "1d") { deadline = Date().addingTimeInterval(86400) }
                QuickDeadlineButton(label: "3d") { deadline = Date().addingTimeInterval(86400 * 3) }
                QuickDeadlineButton(label: "1w") { deadline = Date().addingTimeInterval(86400 * 7) }
                QuickDeadlineButton(label: "1m") { deadline = Date().addingTimeInterval(86400 * 30) }
            }
        }
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
                        .foregroundColor(.primary)
                        .font(.title3)
                }
            }
        }
        .menuStyle(.borderlessButton)
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
                    .font(AppFont.priorityBadge)

                Text(priorityLabel)
                    .font(AppFont.caption)
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
                .font(AppFont.bodyStandardMedium)
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

    private var priorityPrefix: String {
        priority == .p0 ? "🔻P0🔻" : ""
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(symbol: AppSymbols.bellBadge)
                .font(AppFont.headerLargeRegular)
                .foregroundColor(AppColors.warning)

            VStack(alignment: .leading, spacing: 4) {
                Text("Notification to \(memberName)")
                    .font(AppFont.bodyStandardSemibold)

                Text("\(priorityPrefix)\(Date().formatted(date: .abbreviated, time: .shortened)) - [Manager name] has assigned you a new activity with deadline \(deadline.formatted(date: .abbreviated, time: .shortened)): \(activityName).")
                    .font(AppFont.caption)
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

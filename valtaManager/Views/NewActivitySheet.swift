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
    @Environment(AppState.self) private var appState
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
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text("New Activity")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button("Create") {
                    createActivity()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Form
            ScrollView {
                VStack(spacing: 24) {
                    // Activity name
                    FormField(label: "Activity Name", required: true) {
                        TextField("Enter activity name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Description
                    FormField(label: "Description", required: true) {
                        TextEditor(text: $description)
                            .font(.body)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                    
                    // Assigned member
                    FormField(label: "Assign To", required: true) {
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
                                        MemberAvatar(member: member, size: 24)
                                        
                                        Text(member.name)
                                            .foregroundColor(.primary)
                                    }
                                } else {
                                    Text("Select team member")
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(symbol: AppSymbols.chevronDown)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                    }
                    
                    // Priority
                    FormField(label: "Priority", required: true) {
                        HStack(spacing: 8) {
                            ForEach(ActivityPriority.allCases, id: \.self) { p in
                                PriorityOption(
                                    priority: p,
                                    isSelected: priority == p,
                                    action: { priority = p }
                                )
                            }
                        }
                    }
                    
                    // Deadline
                    FormField(label: "Deadline", required: true) {
                        DatePicker(
                            "",
                            selection: $deadline,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                    
                    // Quick deadline buttons
                    HStack(spacing: 8) {
                        QuickDeadlineButton(label: "1h", action: { deadline = Date().addingTimeInterval(3600) })
                        QuickDeadlineButton(label: "4h", action: { deadline = Date().addingTimeInterval(3600 * 4) })
                        QuickDeadlineButton(label: "1d", action: { deadline = Date().addingTimeInterval(86400) })
                        QuickDeadlineButton(label: "3d", action: { deadline = Date().addingTimeInterval(86400 * 3) })
                        QuickDeadlineButton(label: "1w", action: { deadline = Date().addingTimeInterval(86400 * 7) })
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            // Preview
            if isValid {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    NotificationPreview(
                        priority: priority,
                        deadline: deadline,
                        memberName: selectedMember?.name ?? ""
                    )
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .frame(width: 520, height: 620)
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
}

// MARK: - Form Field

struct FormField<Content: View>: View {
    let label: String
    var required: Bool = false
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                
                if required {
                    Text("*")
                        .foregroundColor(AppColors.destructive)
                }
            }
            
            content
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
            .padding(.vertical, 10)
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
                
                Text("Your manager has assigned \(priority.shortName) activity on \(Date().formatted(date: .abbreviated, time: .shortened)) with deadline \(deadline.formatted(date: .abbreviated, time: .shortened)) to you, please start the activity.")
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
        .environment(AppState())
}


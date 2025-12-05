//
//  AddMemberSheet.swift
//  valtaManager
//
//  Sheet for adding a new team member.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct AddMemberSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var email: String = ""
    
    private var isValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    private var previewInitials: String {
        if name.isEmpty { return "?" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
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
                
                Text("Add Team Member")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
                
                Button("Add") {
                    addMember()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Form
            VStack(spacing: 24) {
                // Avatar preview
                VStack(spacing: 12) {
                    MemberAvatar(initials: previewInitials, size: 80)
                        .shadow(color: AppColors.avatar.opacity(0.4), radius: 10, y: 5)
                    
                    Text("Avatar Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 12)
                
                // Name field
                FormField(label: "Full Name", required: true) {
                    TextField("Enter full name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Email field
                FormField(label: "Email", required: true) {
                    TextField("Enter email address", text: $email)
                        .textFieldStyle(.roundedBorder)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .frame(width: 420, height: 340)
    }
    
    private func addMember() {
        let member = TeamMember(
            name: name,
            email: email
        )
        
        appState.addMember(member)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    AddMemberSheet()
        .environment(AppState())
}

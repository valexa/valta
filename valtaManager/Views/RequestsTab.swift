//
//  RequestsTab.swift
//  valtaManager
//
//  Requests tab for viewing and managing completion requests from team members.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct RequestsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        // Content
        Group {
            if appState.completionRequests.isEmpty {
                EmptyRequestsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appState.completionRequests) { request in
                            RequestCard(request: request)
                        }
                    }
                    .padding()
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Spacer()
            }
            ToolbarItem {
                if !appState.completionRequests.isEmpty {
                    Button("Approve All", role: .confirm) {
                        approveAll()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }

    private func approveAll() {
        for request in appState.completionRequests {
            appState.approveCompletion(request)
        }
    }
}


// MARK: - Request Card

struct RequestCard: View {
    let request: CompletionRequest
    @Environment(AppState.self) private var appState
    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Requester avatar
                MemberAvatar(member: request.activity.assignedMember, size: 48)

                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Text(request.activity.assignedMember.name)
                            .font(.system(size: 15, weight: .semibold))

                        Text("requested completion")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(request.requestedAt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Activity details
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            PriorityBadge(priority: request.activity.priority)

                            Text(request.activity.name)
                                .font(.system(size: 14, weight: .medium))
                        }

                        Text(request.activity.description)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(8)

                    // Requested outcome
                    HStack(spacing: 8) {
                        Text("Requested outcome:")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(symbol: request.requestedOutcome.icon)
                            Text(request.requestedOutcome.rawValue)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(request.requestedOutcome.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(request.requestedOutcome.color.opacity(0.15))
                        .cornerRadius(6)

                        Spacer()

                        // Deadline info
                        HStack(spacing: 4) {
                            Image(symbol: AppSymbols.calendarBadgeClock)
                                .font(.system(size: 12))
                            Text("Deadline: \(request.activity.deadline.formatted(date: .abbreviated, time: .shortened))")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(20)

            Divider()

            // Actions
            HStack(spacing: 12) {
                Spacer()

                Button("Reject", role: .destructive) {
                    appState.rejectCompletion(request)
                }
                .buttonStyle(.glass)
                .tint(.orange)

                Button("Approve", role: .confirm) {
                    appState.approveCompletion(request)
                }
                .buttonStyle(.glass)
                .tint(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 6, y: 2)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Empty State

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(symbol: AppSymbols.checkmarkSeal)
                    .font(.system(size: 48))
                    .foregroundStyle(AppGradients.success)
            }

            Text("All Caught Up!")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            Text("No pending completion requests from your team")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    RequestsTab()
        .environment(AppState())
        .frame(width: 800, height: 600)
}


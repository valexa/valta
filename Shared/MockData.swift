//
//  MockData.swift
//  Shared
//
//  Mock data for development and testing purposes.
//  Contains sample TeamMembers, Activities, CompletionRequests, Teams, and ActivityLogEntries.
//
//  Created by vlad on 2025-12-04.
//

import Foundation

// MARK: - Mock Team Members

extension TeamMember {
    static let mockMembers: [TeamMember] = [
        TeamMember(name: "Sarah Chen", email: "sarah.chen@company.com"),
        TeamMember(name: "Marcus Johnson", email: "marcus.j@company.com"),
        TeamMember(name: "Elena Rodriguez", email: "elena.r@company.com"),
        TeamMember(name: "Alex Kim", email: "alex.kim@company.com"),
        TeamMember(name: "Jordan Taylor", email: "jordan.t@company.com"),
        TeamMember(name: "Priya Patel", email: "priya.p@company.com"),
    ]
}

// MARK: - Mock Activities

extension Activity {
    static let mockActivities: [Activity] = {
        let members = TeamMember.mockMembers
        let now = Date()
        let calendar = Calendar.current
        
        return [
            // Sarah Chen - Running Activity 1
            Activity(
                name: "Deploy v2.1 Hotfix",
                description: "Critical production hotfix for authentication bug",
                assignedMember: members[0],
                priority: .p0,
                status: .running,
                createdAt: calendar.date(byAdding: .hour, value: -2, to: now)!,
                deadline: calendar.date(byAdding: .minute, value: 45, to: now)!,
                startedAt: calendar.date(byAdding: .hour, value: -1, to: now)!
            ),
            // Sarah Chen - Running Activity 2
            Activity(
                name: "Backend Service Optimization",
                description: "Optimize database queries for user dashboard",
                assignedMember: members[0],
                priority: .p2,
                status: .running,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                deadline: calendar.date(byAdding: .hour, value: 6, to: now)!,
                startedAt: calendar.date(byAdding: .hour, value: -4, to: now)!
            ),
            // Sarah Chen - Team Member Pending
            Activity(
                name: "Review Security Patches",
                description: "Review and apply latest security patches to staging",
                assignedMember: members[0],
                priority: .p1,
                status: .teamMemberPending,
                createdAt: calendar.date(byAdding: .hour, value: -1, to: now)!,
                deadline: calendar.date(byAdding: .hour, value: 8, to: now)!
            ),
            // Sarah Chen - Manager Pending
            Activity(
                name: "API Rate Limiting Implementation",
                description: "Implement rate limiting for public API endpoints",
                assignedMember: members[0],
                priority: .p1,
                status: .managerPending,
                outcome: .ahead,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now)!,
                deadline: calendar.date(byAdding: .hour, value: 2, to: now)!,
                startedAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            // Sarah Chen - Completed (Ahead)
            Activity(
                name: "CI/CD Pipeline Fix",
                description: "Fix failing tests in deployment pipeline",
                assignedMember: members[0],
                priority: .p0,
                status: .completed,
                outcome: .ahead,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now)!,
                deadline: calendar.date(byAdding: .day, value: -2, to: now)!,
                startedAt: calendar.date(byAdding: .day, value: -3, to: now)!,
                completedAt: calendar.date(byAdding: .hour, value: -60, to: calendar.date(byAdding: .day, value: -2, to: now)!)!
            ),
            // Sarah Chen - Canceled
            Activity(
                name: "Performance Testing",
                description: "Run load tests on new API endpoints",
                assignedMember: members[0],
                priority: .p2,
                status: .canceled,
                createdAt: calendar.date(byAdding: .day, value: -4, to: now)!,
                deadline: calendar.date(byAdding: .day, value: -2, to: now)!
            ),
            // Marcus Johnson
            Activity(
                name: "Code Review: Payment Module",
                description: "Review pull request #342 for new payment integration",
                assignedMember: members[1],
                priority: .p1,
                status: .teamMemberPending,
                createdAt: calendar.date(byAdding: .hour, value: -4, to: now)!,
                deadline: calendar.date(byAdding: .hour, value: 3, to: now)!
            ),
            // Elena Rodriguez
            Activity(
                name: "Update API Documentation",
                description: "Document new endpoints for v2.1 release",
                assignedMember: members[2],
                priority: .p2,
                status: .running,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                deadline: calendar.date(byAdding: .day, value: 1, to: now)!,
                startedAt: calendar.date(byAdding: .hour, value: -6, to: now)!
            ),
            // Alex Kim
            Activity(
                name: "Database Migration Script",
                description: "Write migration script for user preferences table",
                assignedMember: members[3],
                priority: .p1,
                status: .managerPending,
                outcome: .ahead,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now)!,
                deadline: calendar.date(byAdding: .hour, value: 5, to: now)!,
                startedAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            // Jordan Taylor - Completed (JIT)
            Activity(
                name: "UI Component Library Update",
                description: "Update button and form components to new design system",
                assignedMember: members[4],
                priority: .p3,
                status: .completed,
                outcome: .jit,
                createdAt: calendar.date(byAdding: .day, value: -3, to: now)!,
                deadline: calendar.date(byAdding: .day, value: -1, to: now)!,
                startedAt: calendar.date(byAdding: .day, value: -2, to: now)!,
                completedAt: calendar.date(byAdding: .minute, value: 3, to: calendar.date(byAdding: .day, value: -1, to: now)!)!
            ),
            // Priya Patel - Completed (Overrun)
            Activity(
                name: "Security Audit Checklist",
                description: "Complete quarterly security audit for backend services",
                assignedMember: members[5],
                priority: .p0,
                status: .completed,
                outcome: .overrun,
                createdAt: calendar.date(byAdding: .day, value: -5, to: now)!,
                deadline: calendar.date(byAdding: .day, value: -2, to: now)!,
                startedAt: calendar.date(byAdding: .day, value: -4, to: now)!,
                completedAt: calendar.date(byAdding: .hour, value: 18, to: calendar.date(byAdding: .day, value: -2, to: now)!)!
            ),
        ]
    }()
}

// MARK: - Mock Completion Requests

extension CompletionRequest {
    static let mockRequests: [CompletionRequest] = {
        let activities = Activity.mockActivities
        return [
            // Sarah's API Rate Limiting (index 3)
            CompletionRequest(
                activity: activities[3],
                requestedAt: Date().addingTimeInterval(-1800),
                requestedOutcome: .ahead
            ),
            // Alex Kim's Database Migration (index 8)
            CompletionRequest(
                activity: activities[8],
                requestedAt: Date().addingTimeInterval(-3600),
                requestedOutcome: .ahead
            ),
        ]
    }()
}

// MARK: - Mock Team

extension Team {
    static let mockTeam = Team(
        name: "Platform Engineering",
        members: TeamMember.mockMembers,
        activities: Activity.mockActivities
    )
}

// MARK: - Mock Activity Log Entries

extension ActivityLogEntry {
    static let mockLogEntries: [ActivityLogEntry] = {
        let activities = Activity.mockActivities
        let now = Date()
        let calendar = Calendar.current
        
        return [
            // Recent: Sarah's completion request for API Rate Limiting
            ActivityLogEntry(
                activity: activities[3],
                action: .completionRequested,
                timestamp: calendar.date(byAdding: .minute, value: -30, to: now)!,
                performedBy: "Sarah Chen"
            ),
            // Recent: Sarah's running activity started
            ActivityLogEntry(
                activity: activities[0],
                action: .started,
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!,
                performedBy: "Sarah Chen"
            ),
            // Recent: Sarah's second running activity started
            ActivityLogEntry(
                activity: activities[1],
                action: .started,
                timestamp: calendar.date(byAdding: .hour, value: -4, to: now)!,
                performedBy: "Sarah Chen"
            ),
            // Recent: Elena started her activity
            ActivityLogEntry(
                activity: activities[7],
                action: .started,
                timestamp: calendar.date(byAdding: .hour, value: -6, to: now)!,
                performedBy: "Elena Rodriguez"
            ),
            // Yesterday: Priya's overrun completion
            ActivityLogEntry(
                activity: activities[10],
                action: .completed,
                timestamp: calendar.date(byAdding: .day, value: -1, to: now)!,
                performedBy: "Victoria Lane"
            ),
            // Yesterday: Jordan's JIT completion
            ActivityLogEntry(
                activity: activities[9],
                action: .completed,
                timestamp: calendar.date(byAdding: .day, value: -1, to: now)!,
                performedBy: "Victoria Lane"
            ),
            // Yesterday: Activity created for Sarah
            ActivityLogEntry(
                activity: activities[2],
                action: .created,
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!,
                performedBy: "Victoria Lane"
            ),
            // 2 days ago: Sarah's CI/CD completed ahead
            ActivityLogEntry(
                activity: activities[4],
                action: .completed,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                performedBy: "Victoria Lane"
            ),
            // 2 days ago: Performance testing canceled
            ActivityLogEntry(
                activity: activities[5],
                action: .canceled,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                performedBy: "Victoria Lane"
            ),
            // 3 days ago: Activity created for Jordan
            ActivityLogEntry(
                activity: activities[9],
                action: .created,
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                performedBy: "Victoria Lane"
            ),
            // 5 days ago: Activity created for Priya
            ActivityLogEntry(
                activity: activities[10],
                action: .created,
                timestamp: calendar.date(byAdding: .day, value: -5, to: now)!,
                performedBy: "Victoria Lane"
            ),
        ]
    }()
}


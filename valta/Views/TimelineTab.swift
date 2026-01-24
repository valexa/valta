//
//  TimelineTab.swift
//  valta
//
//  Horizontally scrollable timeline showing team activity intensity per week.
//  Adapted for Team Member app with outcome-based color coding.
//

import SwiftUI

struct TimelineTab: View {
    @Environment(TeamMemberAppState.self) private var appState
    
    private var weeklyData: [(week: Date, active: [MemberActivityCount], inactive: [MemberActivityCount])] {
        let calendar = Calendar.current
        let allActivities = appState.team.activities
        let allMembers = appState.team.members
        
        // Group activities by week start
        let grouped = Dictionary(grouping: allActivities) { activity in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: activity.createdAt)
            return calendar.date(from: components)!
        }
        
        return grouped.map { week, activities in
            let memberGrouped = Dictionary(grouping: activities) { $0.assignedMember.id }
            
            var active: [MemberActivityCount] = []
            var inactive: [MemberActivityCount] = []
            
            for member in allMembers {
                if let memberActivities = memberGrouped[member.id] {
                    active.append(MemberActivityCount(
                        member: member,
                        count: memberActivities.count,
                        activities: memberActivities.map { (title: $0.name, color: $0.outcome?.color ?? .blue) }
                    ))
                } else {
                    inactive.append(MemberActivityCount(member: member, count: 0, activities: []))
                }
            }
            
            return (week: week, active: active.sorted { $0.count > $1.count }, inactive: inactive)
        }.sorted { $0.week < $1.week }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: true) {
                ZStack(alignment: .center) {
                    // Continuous Central Axis
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 5)
                        .frame(maxWidth: .infinity)
                    
                    HStack(alignment: .center, spacing: 0) {
                        if weeklyData.isEmpty {
                            EmptyStateView(
                                icon: AppSymbols.calendar,
                                title: "No Activity Data",
                                message: "Assign activities to see them in the timeline."
                            )
                            .frame(width: 800)
                        } else {
                            ForEach(weeklyData, id: \.week) { weekData in
                                WeeklySection(
                                    week: weekData.week,
                                    active: weekData.active,
                                    inactive: weekData.inactive
                                )
                            }
                        }
                    }
                }
                .frame(minWidth: geometry.size.width)
            }
        }
    }
}

// MARK: - Subviews

struct WeeklySection: View {
    let week: Date
    let active: [MemberActivityCount]
    let inactive: [MemberActivityCount]
    
    var body: some View {
        VStack(spacing: 0) {
            // Active Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppSpacing.md) {
                    ForEach(active) { data in
                        MemberBubble(member: data.member, count: data.count, activities: data.activities, isActive: true)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            
            // Date Label (Overlaying the background line)
            ZStack {
                Text(week.formatted(.dateTime.day().month(.abbreviated)))
                    .font(AppFont.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.9))
                    .clipShape(Capsule())
            }
            .padding(.vertical)
            .frame(width: 140)
            
            // Inactive Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppSpacing.md) {
                    ForEach(inactive) { data in
                        MemberBubble(member: data.member, count: 0, activities: [], isActive: false)
                    }
                }
                .padding(.vertical, AppSpacing.lg)
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 140)
    }
}

struct MemberBubble: View {
    let member: TeamMember
    let count: Int
    let activities: [(title: String, color: Color)]
    let isActive: Bool
    
    @State private var showingPopover = false
    
    private var bubbleSize: CGFloat {
        if !isActive { return 36 }
        return 40 + min(CGFloat(count * 6), 50)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            // Glass Bubble
            Button(action: {
                if isActive {
                    showingPopover.toggle()
                }
            }) {
                Text(member.initials)
                    .font(.system(size: bubbleSize * 0.36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(width: bubbleSize, height: bubbleSize)
            .tint(.brown)
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .opacity(isActive ? 1.0 : 0.4)
            .grayscale(isActive ? 0 : 1.0)
            .popover(isPresented: $showingPopover) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(member.name)
                        .font(.headline)
                    Divider()
                    ForEach(0..<activities.count, id: \.self) { index in
                        let activity = activities[index]
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(activity.color)
                                .frame(width: 8, height: 8)
                                .offset(y: 4)
                            Text(activity.title)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .frame(minWidth: 200, maxWidth: 300)
            }
            
            if isActive {
                Text("\(count)")
                    .font(AppFont.caption)
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .help(isActive ? "\(member.name): \(count) activities" : "\(member.name): No activities")
    }
}

// MARK: - Helper Models

struct MemberActivityCount: Identifiable {
    let member: TeamMember
    let count: Int
    let activities: [(title: String, color: Color)]
    var id: UUID { member.id }
}

#Preview {
    TimelineTab()
        .environment(TeamMemberAppState())
}

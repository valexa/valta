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
    @State private var filterState = ActivityFilterState()

    private var weeklyData: [(week: Date, active: [MemberActivityCount], inactive: [MemberActivityCount])] {
        let calendar = Calendar.current
        let filteredActivities = filterState.apply(to: appState.team.activities, currentMemberId: appState.currentMember?.id)
        let allMembers = appState.team.members

        // Group activities by week start using fallback date logic:
        // completionAt > startedAt > createdAt
        let grouped = Dictionary(grouping: filteredActivities) { activity in
            let dateToUse = activity.completedAt ?? activity.startedAt ?? activity.createdAt
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dateToUse)
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
                        .fill(Color.secondary.opacity(0.15))
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
        .searchable(text: $filterState.searchText, placement: .toolbarPrincipal, prompt: "Search timeline...")
        .toolbar {
            SharedFilterBar(filterState: filterState)
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
                        MemberBubble(member: data.member, memberTotal: data.count, activities: data.activities, isActive: true)
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
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.5))
                    .clipShape(Capsule())
                    .glassEffect()
            }
            .padding(.vertical)
            .frame(width: 140)

            // Inactive Area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: AppSpacing.md) {
                    ForEach(inactive) { data in
                        MemberBubble(member: data.member, memberTotal: 0, activities: [], isActive: false)
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
    let memberTotal: Int
    let activities: [(title: String, color: Color)]
    let isActive: Bool

    @State private var showingPopover = false

    private var bubbleSize: CGFloat {
        if !isActive { return 36 }
        return 40 + min(CGFloat(memberTotal * 6), 50)
    }

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            // Member Avatar with Activity Badge
            MemberAvatarColored(
                member: member,
                size: bubbleSize,
                badge: isActive && memberTotal > 0 ? "\(memberTotal)" : nil
            )
            .padding(4)
            .opacity(isActive ? 1.0 : 0.4)
            .onTapGesture {
                if isActive {
                    showingPopover.toggle()
                }
            }
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
        }
        .help(isActive ? "\(member.name): \(memberTotal) activities" : "\(member.name): No activities")
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

//
//  AnalyticsTab.swift
//  valtaManager
//
//  Analytics view with Swift Charts showing activity outcomes timeline
//  and activity creation/starts timeline with 1-day increments.
//
//  Created by vlad on 2025-12-18.
//

import SwiftUI
import Charts

// MARK: - Analytics Tab

struct AnalyticsTab: View {
    @Environment(ManagerAppState.self) private var appState

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxxl) {
                // Header
                Text("Activity Analytics")
                    .font(AppFont.headerSection)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Outcomes Timeline Chart
                OutcomesTimelineChart(activities: appState.completedActivities)

                // Creation & Starts Timeline Chart
                ActivityTimelineChart(activities: appState.team.activities)
            }
            .padding(AppSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Outcomes Timeline Chart

struct OutcomesTimelineChart: View {
    let activities: [Activity]

    private var useMonthlyGrouping: Bool {
        guard let first = activities.compactMap({ $0.completedAt }).min(),
              let last = activities.compactMap({ $0.completedAt }).max() else {
            return false
        }
        let diff = Calendar.current.dateComponents([.day], from: first, to: last)
        return (diff.day ?? 0) > 30
    }

    private var chartData: [OutcomeDataPoint] {
        // Group completed activities by period and outcome
        let calendar = Calendar.current
        let _: Calendar.Component = useMonthlyGrouping ? .month : .day

        // Get all completed activities with outcomes
        let completedWithOutcome = activities.filter { $0.completedAt != nil && $0.outcome != nil }

        // Group by period
        var dataPoints: [OutcomeDataPoint] = []
        let grouped = Dictionary(grouping: completedWithOutcome) { activity -> Date in
            if useMonthlyGrouping {
                let components = calendar.dateComponents([.year, .month], from: activity.completedAt!)
                return calendar.date(from: components)!
            } else {
                return calendar.startOfDay(for: activity.completedAt!)
            }
        }

        for (period, periodActivities) in grouped.sorted(by: { $0.key < $1.key }) {
            let ahead = periodActivities.filter { $0.outcome == .ahead }.count
            let jit = periodActivities.filter { $0.outcome == .jit }.count
            let overrun = periodActivities.filter { $0.outcome == .overrun }.count

            if ahead > 0 { dataPoints.append(OutcomeDataPoint(date: period, count: ahead, outcome: .ahead)) }
            if jit > 0 { dataPoints.append(OutcomeDataPoint(date: period, count: jit, outcome: .jit)) }
            if overrun > 0 { dataPoints.append(OutcomeDataPoint(date: period, count: overrun, outcome: .overrun)) }
        }

        return dataPoints
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            Text("Completion Outcomes")
                .font(AppFont.bodyPrimary)

            if chartData.isEmpty {
                emptyState
            } else {
                Chart(chartData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: useMonthlyGrouping ? .month : .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(by: .value("Outcome", point.outcome.displayName))
                }
                .chartForegroundStyleScale([
                    "Ahead": AppColors.outcomeAhead,
                    "Just In Time": AppColors.outcomeJIT,
                    "Overrun": AppColors.outcomeOverrun
                ])
                .chartXAxis {
                    if useMonthlyGrouping {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.year().month(.abbreviated))
                        }
                    } else {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .automatic)
                }
                .chartLegend(position: .top)
                .frame(height: 250)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No completed activities yet")
                .font(AppFont.bodyStandard)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Activity Timeline Chart

struct ActivityTimelineChart: View {
    let activities: [Activity]

    private var useMonthlyGrouping: Bool {
        guard let first = activities.map({ $0.createdAt }).min(),
              let last = activities.map({ $0.createdAt }).max() else {
            return false
        }
        let diff = Calendar.current.dateComponents([.day], from: first, to: last)
        return (diff.day ?? 0) > 30
    }

    private var chartData: [ActivityTimelinePoint] {
        let calendar = Calendar.current
        var dataPoints: [ActivityTimelinePoint] = []

        let groupDate: (Date) -> Date = { date in
            if useMonthlyGrouping {
                let components = calendar.dateComponents([.year, .month], from: date)
                return calendar.date(from: components)!
            } else {
                return calendar.startOfDay(for: date)
            }
        }

        // Group by creation date
        let createdGrouped = Dictionary(grouping: activities) { activity -> Date in
            groupDate(activity.createdAt)
        }

        for (period, periodActivities) in createdGrouped {
            dataPoints.append(ActivityTimelinePoint(date: period, count: periodActivities.count, type: .created))
        }

        // Group by start date
        let startedActivities = activities.filter { $0.startedAt != nil }
        let startedGrouped = Dictionary(grouping: startedActivities) { activity -> Date in
            groupDate(activity.startedAt!)
        }

        for (period, periodActivities) in startedGrouped {
            dataPoints.append(ActivityTimelinePoint(date: period, count: periodActivities.count, type: .started))
        }

        // Group by completion date
        let completedActivities = activities.filter { $0.completedAt != nil }
        let completedGrouped = Dictionary(grouping: completedActivities) { activity -> Date in
            groupDate(activity.completedAt!)
        }

        for (period, periodActivities) in completedGrouped {
            dataPoints.append(ActivityTimelinePoint(date: period, count: periodActivities.count, type: .completed))
        }

        return dataPoints.sorted { $0.date < $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            Text("Activity Timeline")
                .font(AppFont.bodyPrimary)

            if chartData.isEmpty {
                emptyState
            } else {
                Chart(chartData) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: useMonthlyGrouping ? .month : .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(by: .value("Type", point.type.displayName))
                    .symbol(by: .value("Type", point.type.displayName))

                    PointMark(
                        x: .value("Date", point.date, unit: useMonthlyGrouping ? .month : .day),
                        y: .value("Count", point.count)
                    )
                    .foregroundStyle(by: .value("Type", point.type.displayName))
                }
                .chartForegroundStyleScale([
                    "Created": Color.purple,
                    "Started": Color.teal,
                    "Completed": Color.green
                ])
                .chartXAxis {
                    if useMonthlyGrouping {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.year().month(.abbreviated))
                        }
                    } else {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .automatic)
                }
                .chartLegend(position: .top)
                .frame(height: 250)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No activity data yet")
                .font(AppFont.bodyStandard)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Data Models

struct OutcomeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let outcome: ActivityOutcome
}

struct ActivityTimelinePoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let type: ActivityEventType
}

enum ActivityEventType {
    case created
    case started
    case completed

    var displayName: String {
        switch self {
        case .created: return "Created"
        case .started: return "Started"
        case .completed: return "Completed"
        }
    }
}

// MARK: - ActivityOutcome Extension

extension ActivityOutcome {
    var displayName: String {
        switch self {
        case .ahead: return "Ahead"
        case .jit: return "Just In Time"
        case .overrun: return "Overrun"
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsTab()
        .environment(ManagerAppState())
        .frame(width: 800, height: 600)
}

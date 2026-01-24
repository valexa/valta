//
//  ProjectionsTab.swift
//  valtaManager
//
//  Projections view showing ML-based outcome projections per team member
//  and priority level based on historical performance data.
//
//  Created by vlad on 2025-12-19.
//

import SwiftUI
import Charts

// MARK: - Projections Tab

struct ProjectionsTab: View {
    @Environment(ManagerAppState.self) private var appState

    private var projections: [MemberPerformanceSummary] {
        OutcomeProjectionService.generateProjections(
            activities: appState.team.activities,
            members: appState.team.members
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xxxl) {
                // Header
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Outcome Projections")
                        .font(AppFont.headerSection)

                    Text("Based on historical performance of \(appState.completedActivities.count) completed activities")
                        .font(AppFont.bodySmall)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Warning if not enough data
                if appState.completedActivities.count < 10 {
                    DataWarningBanner(completedCount: appState.completedActivities.count)
                }

                // Member Performance Cards
                ForEach(projections) { summary in
                    MemberProjectionCard(summary: summary)
                }

                if projections.isEmpty {
                    EmptyProjectionsView()
                }
            }
            .padding(AppSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Data Warning Banner

struct DataWarningBanner: View {
    let completedCount: Int

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(symbol: AppSymbols.infoCircle)
                .font(AppFont.bodyPrimary)
                .foregroundColor(.orange)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Limited Data Available")
                    .font(AppFont.bodyStandardSemibold)
                Text("Projections improve with more completed activities. Currently based on \(completedCount) activities (recommend 50+).")
                    .font(AppFont.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(AppSpacing.base)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(Color.orange.opacity(0.1))
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Member Projection Card

struct MemberProjectionCard: View {
    @Environment(\.theme) private var theme

    let summary: MemberPerformanceSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Header with member info and score
            HStack {
                // Avatar
                MemberAvatarColored(member: summary.member, size: theme.avatarSize * 1.5)
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(summary.member.name)
                        .font(AppFont.bodyPrimary)

                    Text("\(summary.totalCompleted) completed activities")
                        .font(AppFont.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Performance Score
                PerformanceScoreBadge(score: summary.performanceScore)
            }

            Divider()

            // Overall Distribution Chart
            if summary.totalCompleted > 0 {
                OverallDistributionChart(summary: summary)
            }

            // Projections by Priority
            Text("Projections by Priority")
                .font(AppFont.bodyStandardSemibold)
                .padding(.top, AppSpacing.xs)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppSpacing.sm) {
                ForEach(summary.projections) { projection in
                    PriorityProjectionCell(projection: projection)
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.lg)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Performance Score Badge

struct PerformanceScoreBadge: View {
    let score: Double

    private var scoreColor: Color {
        switch score {
        case 85...100: return AppColors.outcomeAhead
        case 65..<85: return AppColors.outcomeJIT
        default: return AppColors.outcomeOverrun
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text("\(Int(score))")
                .font(AppFont.headerSection)
                .foregroundColor(scoreColor)
            Text("Score")
                .font(AppFont.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.md)
                .fill(scoreColor.opacity(0.1))
        )
    }
}

// MARK: - Overall Distribution Chart

struct OverallDistributionChart: View {
    let summary: MemberPerformanceSummary

    private var chartData: [(outcome: String, count: Int, color: Color)] {
        [
            ("Ahead", summary.aheadCount, AppColors.outcomeAhead),
            ("JIT", summary.jitCount, AppColors.outcomeJIT),
            ("Overrun", summary.overrunCount, AppColors.outcomeOverrun)
        ]
    }

    var body: some View {
        HStack(spacing: AppSpacing.xl) {
            // Bar Chart
            Chart {
                ForEach(chartData, id: \.outcome) { item in
                    BarMark(
                        x: .value("Outcome", item.outcome),
                        y: .value("Count", item.count)
                    )
                    .foregroundStyle(item.color.gradient)
                    .cornerRadius(AppCornerRadius.xs)
                }
            }
            .chartYAxis {
                AxisMarks(preset: .automatic)
            }
            .frame(height: 120)
            .frame(maxWidth: 200)

            // Legend with percentages
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                OutcomeLegendRow(
                    outcome: .ahead,
                    percentage: summary.aheadRate,
                    count: summary.aheadCount
                )
                OutcomeLegendRow(
                    outcome: .jit,
                    percentage: summary.jitRate,
                    count: summary.jitCount
                )
                OutcomeLegendRow(
                    outcome: .overrun,
                    percentage: summary.overrunRate,
                    count: summary.overrunCount
                )
            }

            Spacer()
        }
    }
}

// MARK: - Outcome Legend Row

struct OutcomeLegendRow: View {
    let outcome: ActivityOutcome
    let percentage: Double
    let count: Int

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Circle()
                .fill(outcome.color)
                .frame(width: 8, height: 8)

            Text(outcome.rawValue)
                .font(AppFont.bodySmall)
                .frame(width: 80, alignment: .leading)

            Text("\(Int(percentage * 100))%")
                .font(AppFont.bodyStandardSemibold)
                .foregroundColor(outcome.color)
                .frame(width: 40, alignment: .trailing)

            Text("(\(count))")
                .font(AppFont.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Priority Projection Cell

struct PriorityProjectionCell: View {
    let projection: OutcomeProjection

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            // Priority header
            HStack(spacing: AppSpacing.xxs) {
                Image(symbol: projection.priority.icon)
                Text(projection.priority.shortName)
            }
            .font(AppFont.bodyStandardSemibold)
            .foregroundColor(projection.priority.color)

            // Predicted outcome
            HStack(spacing: AppSpacing.xxs) {
                Image(symbol: projection.predictedOutcome.icon)
                    .font(AppFont.caption)
                Text(projection.predictedOutcome.rawValue)
                    .font(AppFont.caption)
            }
            .foregroundColor(projection.predictedOutcome.color)

            // Confidence indicator
            Text(projection.confidence.description)
                .font(AppFont.caption)
                .foregroundColor(.secondary)
                .opacity(0.7)

            // Sample size
            if projection.sampleSize > 0 {
                Text("n=\(projection.sampleSize)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
            }
        }
        .padding(AppSpacing.sm)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppCornerRadius.sm)
                .fill(projection.predictedOutcome.color.opacity(0.08))
                .stroke(projection.predictedOutcome.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Empty State

struct EmptyProjectionsView: View {
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(symbol: AppSymbols.tabProjections)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Team Members")
                .font(AppFont.bodyPrimary)

            Text("Add team members to start generating projections")
                .font(AppFont.bodySmall)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xxxl)
    }
}

// MARK: - Preview

#Preview {
    ProjectionsTab()
        .environment(ManagerAppState())
        .frame(width: 900, height: 700)
}

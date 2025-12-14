//
//  valtaWidgetsLiveActivity.swift
//  valtaWidgets
//
//  Created by vlad on 14/12/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivityAttributes.self) { context in
            // Lock Screen view
            HStack {
                Text(context.attributes.activityName)
                    .font(.headline)
                Spacer()
                if context.state.isOverdue {
                    Text("Overdue")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    Text(Date(timeIntervalSince1970: context.attributes.deadlineTimestamp), style: .timer)
                        .font(.caption)
                        .monospacedDigit()
                }
            }
            .padding()
        } dynamicIsland: { context in
            // Dynamic Island views
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.priority)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.timeRemaining)s")
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.activityName)
                }
            } compactLeading: {
                Text(context.attributes.priority)
            } compactTrailing: {
                Text("\(context.state.timeRemaining)s")
            } minimal: {
                Image(systemName: "timer")
            }
        }
    }
}

#Preview("Notification", as: .content, using: LiveActivityAttributes(
    activityName: "Review Q4 Reports",
    priority: "P1",
    priorityColorHex: "#FF6B35",
    memberName: "John Doe",
    deadlineTimestamp: Date().addingTimeInterval(3600).timeIntervalSince1970,
    activityIdString: UUID().uuidString
)) {
    LiveActivityWidget()
} contentStates: {
    LiveActivityAttributes.ContentState(
        timeRemaining: 3600,
        isOverdue: false,
        statusText: "Running"
    )
    LiveActivityAttributes.ContentState(
        timeRemaining: -300,
        isOverdue: true,
        statusText: "Overdue!"
    )
}

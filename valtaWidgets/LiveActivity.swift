//
//  LiveActivity.swift
//  valtaWidgets
//
//  Live Activity attributes and content state for activity countdown.
//  Used by the Widget Extension for Dynamic Island and Lock Screen.
//
//  ActivityKit is only available on iOS 16.1+, not macOS.
//
//  Created by vlad on 2025-12-14.
//

#if os(iOS)
import ActivityKit
import SwiftUI

/// Attributes for an Activity Live Activity (countdown timer)
public struct LiveActivityAttributes: ActivityAttributes {

    /// Dynamic content that updates during the Live Activity
    public struct ContentState: Codable, Hashable {
        /// Time remaining in seconds (negative if overdue)
        public var timeRemaining: Int

        /// Whether the activity is overdue
        public var isOverdue: Bool

        /// Current status text
        public var statusText: String

        public init(timeRemaining: Int, isOverdue: Bool, statusText: String) {
            self.timeRemaining = timeRemaining
            self.isOverdue = isOverdue
            self.statusText = statusText
        }
    }

    // Static attributes that don't change during the Live Activity
    /// Activity name
    public var activityName: String

    /// Activity priority
    public var priority: String

    /// Priority color (as hex string for widget compatibility)
    public var priorityColorHex: String

    /// Member name
    public var memberName: String

    /// Deadline as Unix timestamp
    public var deadlineTimestamp: TimeInterval
    
    /// Activity ID String (for mapping back to app model)
    public var activityIdString: String

    public init(activityName: String, priority: String, priorityColorHex: String, memberName: String, deadlineTimestamp: TimeInterval, activityIdString: String) {
        self.activityName = activityName
        self.priority = priority
        self.priorityColorHex = priorityColorHex
        self.memberName = memberName
        self.deadlineTimestamp = deadlineTimestamp
        self.activityIdString = activityIdString
    }
}
#endif

//
//  AppSymbols.swift
//  Shared
//
//  Centralized SF Symbol names used throughout both apps.
//  Use these instead of hardcoded strings for consistency and refactoring safety.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

/// Centralized SF Symbol definitions for the Live Team Activities apps
enum AppSymbols {

    // MARK: - Status Icons

    static let running = "play.circle.fill"
    static let completed = "checkmark.circle.fill"
    static let canceled = "xmark.circle.fill"
    static let managerPending = "person.badge.clock"
    static let teamMemberPending = "clock.badge.questionmark"

    // MARK: - Outcome Icons

    static let outcome = "timer"
    static let outcomeAhead = "hare.fill"
    static let outcomeJIT = "clock.fill"
    static let outcomeOverrun = "tortoise.fill"

    // MARK: - Action Icons

    static let play = "play.fill"
    static let checkmark = "checkmark"
    static let checkmarkSeal = "checkmark.seal.fill"
    static let xmark = "xmark"
    static let xmarkCircleFill = "xmark.circle.fill"
    static let plus = "plus"
    static let plusCircleFill = "plus.circle.fill"
    static let paperplaneCircleFill = "paperplane.circle.fill"

    // MARK: - Navigation Icons

    static let arrowRight = "arrow.right"
    static let arrowLeft = "arrow.left"
    static let chevronDown = "chevron.down"
    static let chevronRight = "chevron.right"

    // MARK: - Time & Calendar Icons

    static let clock = "clock"
    static let clockFill = "clock.fill"
    static let calendar = "calendar"
    static let calendarBadgeClock = "calendar.badge.clock"
    static let hourglass = "hourglass"
    static let timer = "timer"
    static let docText = "doc.text"

    // MARK: - Warning & Info Icons

    static let exclamationTriangle = "exclamationmark.triangle.fill"
    static let infoCircle = "info.circle"
    static let bellBadge = "bell.badge.fill"

    // MARK: - People & Team Icons

    static let person3Sequence = "person.3.sequence.fill"
    static let person3 = "person.3"
    static let personBadgePlus = "person.badge.plus"
    static let person2Fill = "person.2.fill"

    // MARK: - UI Icons

    static let magnifyingGlass = "magnifyingglass"
    static let ellipsisCircle = "ellipsis.circle"
    static let filter = "line.3.horizontal.decrease.circle"
    static let flagFill = "flag.fill"
    static let flagSlash = "flag.slash"
    static let flag = "flag"
    static let flagBadge = "flag.badge.ellipsis"
    static let flagCheckered = "flag.checkered"
    static let tray = "tray"
    static let listBullet = "list.bullet.rectangle"
    static let listBulletClipboard = "list.bullet.clipboard"
    static let trayFullFill = "tray.full.fill"
}

// MARK: - Image Extension

extension Image {
    /// Create an image from an AppSymbols constant
    init(symbol: String) {
        self.init(systemName: symbol)
    }
}

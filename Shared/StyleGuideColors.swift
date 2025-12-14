//
//  StyleGuideColors.swift
//  Shared
//
//  Centralized color and gradient definitions for the Live Team Activities apps.
//  IMPORTANT: Only colors and gradients should be defined in this file.
//  For fonts, see StyleGuideFonts.swift
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - App Colors

/// Centralized color definitions for the Live Team Activities apps
enum AppColors {

    // MARK: - Priority Colors

    /// P0 Critical - Red
    static let priorityP0 = Color(red: 0.9, green: 0.2, blue: 0.3)
    /// P1 High - Dark Gray
    static let priorityP1 = Color(red: 0.35, green: 0.35, blue: 0.35)
    /// P2 Medium - Medium Gray
    static let priorityP2 = Color(red: 0.55, green: 0.55, blue: 0.55)
    /// P3 Low - Light Gray
    static let priorityP3 = Color(red: 0.72, green: 0.72, blue: 0.72)

    // MARK: - Outcome Colors

    /// Ahead of schedule - Green
    static let outcomeAhead = Color(red: 0.2, green: 0.8, blue: 0.4)
    /// Just in time - Yellow
    static let outcomeJIT = Color(red: 0.95, green: 0.75, blue: 0.2)
    /// Overrun - Red
    static let outcomeOverrun = Color(red: 0.9, green: 0.2, blue: 0.3)

    // MARK: - Status Colors

    /// Running status - Blue
    static let statusRunning = Color.blue
    /// Completed status - Green
    static let statusCompleted = Color.green
    /// Canceled status - Gray
    static let statusCanceled = Color.gray
    /// Manager pending - Red (awaiting manager approval)
    static let statusManagerPending = Color(red: 0.9, green: 0.2, blue: 0.3)
    /// Team member pending - Purple (awaiting team member to start)
    static let statusTeamMemberPending = Color(red: 0.6, green: 0.4, blue: 0.9)

    // MARK: - Stats Colors

    /// Total/neutral stat - Light gray
    static let statTotal = Color(red: 0.65, green: 0.65, blue: 0.65)

    // MARK: - Action Colors

    /// Destructive/cancel actions - Red (same as priorityP0/outcomeOverrun)
    static let destructive = Color(red: 0.9, green: 0.2, blue: 0.3)
    /// Success/confirm actions - Green (same as statusCompleted)
    static let success = Color.green
    /// Warning/caution - Orange
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.2)

    // MARK: - Avatar

    /// Neutral avatar color for all team members
    static let avatar = Color(red: 0.45, green: 0.5, blue: 0.55)

    // MARK: - UI Colors

    /// Shadow color
    static let shadow = Color.black

    // MARK: - Manager App Theme (Purple/Blue)

    enum Manager {
        /// Primary gradient start
        static let primary = Color(red: 0.4, green: 0.5, blue: 1.0)
        /// Primary gradient end
        static let primaryEnd = Color(red: 0.6, green: 0.4, blue: 1.0)
        /// Secondary accent
        static let secondary = Color(red: 0.5, green: 0.4, blue: 0.9)

        /// Background gradient colors
        static let backgroundStart = Color(red: 0.08, green: 0.08, blue: 0.12)
        static let backgroundMid = Color(red: 0.12, green: 0.10, blue: 0.18)
        static let backgroundEnd = Color(red: 0.08, green: 0.08, blue: 0.12)

        /// Ambient glow colors for background effects
        static let glowPrimary = Color(red: 0.4, green: 0.5, blue: 1.0)
        static let glowSecondary = Color(red: 0.6, green: 0.3, blue: 0.9)

        /// Icon/accent colors
        static let iconGradientStart = Color(red: 0.4, green: 0.6, blue: 1.0)
        static let iconGradientEnd = Color(red: 0.6, green: 0.4, blue: 1.0)

        /// Add members step

        /// Team name step
        static let teamNameStart = Color(red: 0.4, green: 0.7, blue: 1.0)
        static let teamNameEnd = Color(red: 0.5, green: 0.5, blue: 1.0)
    }

    // MARK: - Team Member App Theme (Teal/Cyan)

    enum TeamMember {
        /// Primary gradient start
        static let primary = Color(red: 0.2, green: 0.7, blue: 0.8)
        /// Primary gradient end
        static let primaryEnd = Color(red: 0.3, green: 0.5, blue: 0.8)
        /// Secondary accent
        static let secondary = Color(red: 0.3, green: 0.6, blue: 0.9)

        /// Background gradient colors
        static let backgroundStart = Color(red: 0.06, green: 0.10, blue: 0.14)
        static let backgroundMid = Color(red: 0.08, green: 0.14, blue: 0.18)
        static let backgroundEnd = Color(red: 0.06, green: 0.10, blue: 0.14)

        /// Ambient glow colors for background effects
        static let glowPrimary = Color(red: 0.2, green: 0.7, blue: 0.8)
        static let glowSecondary = Color(red: 0.3, green: 0.6, blue: 0.9)

        /// Selection/success indicator
        static let selectionStart = Color(red: 0.2, green: 0.8, blue: 0.6)
        static let selectionEnd = Color(red: 0.3, green: 0.7, blue: 0.7)
    }

}

// MARK: - Gradients

enum AppGradients {

    // MARK: - Manager App

    /// Primary button gradient for manager app
    static let managerPrimary = LinearGradient(
        colors: [AppColors.Manager.primary, AppColors.Manager.secondary],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Onboarding background for manager app
    static let managerBackground = LinearGradient(
        colors: [
            AppColors.Manager.backgroundStart,
            AppColors.Manager.backgroundMid,
            AppColors.Manager.backgroundEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Icon gradient for manager app
    static let managerIcon = LinearGradient(
        colors: [AppColors.Manager.iconGradientStart, AppColors.Manager.iconGradientEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Team Member App

    /// Onboarding background for team member app
    static let teamMemberBackground = LinearGradient(
        colors: [
            AppColors.TeamMember.backgroundStart,
            AppColors.TeamMember.backgroundMid,
            AppColors.TeamMember.backgroundEnd
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Selection indicator gradient
    static let teamMemberSelection = LinearGradient(
        colors: [AppColors.TeamMember.selectionStart, AppColors.TeamMember.selectionEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Shared

    /// Success gradient (green)
    static let success = LinearGradient(
        colors: [AppColors.success, AppColors.success.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Avatar gradient
    static let avatar = AppColors.avatar.gradient
}

// MARK: - Cross-Platform Color Extensions

extension Color {
    #if os(macOS)
    static let controlBackground = Color(NSColor.controlBackgroundColor)
    static let windowBackground = Color(NSColor.windowBackgroundColor)
    #else
    static let controlBackground = Color(UIColor.secondarySystemBackground)
    static let windowBackground = Color(UIColor.systemBackground)
    #endif
}

// MARK: - Color toHex Extension

extension Color {
    /// Converts the color to a 6-character hex string (e.g. "#FF0000").
    /// Returns nil if conversion is not possible (e.g. system colors).
    func toHex() -> String? {
        #if canImport(UIKit)
        // UIKit (iOS, iPadOS, visionOS)
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return nil }
        return String(format: "#%02X%02X%02X",
                      Int(red * 255),
                      Int(green * 255),
                      Int(blue * 255))
        #elseif canImport(AppKit)
        // AppKit (macOS)
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else { return nil }
        return String(format: "#%02X%02X%02X",
                      Int(rgbColor.redComponent * 255),
                      Int(rgbColor.greenComponent * 255),
                      Int(rgbColor.blueComponent * 255))
        #else
        return nil
        #endif
    }
}

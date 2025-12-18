//
//  StyleGuideFonts.swift
//  Shared
//
//  Centralized font definitions for the Live Team Activities apps.
//  All font sizes, weights, and styles should be defined here.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Font Sizes

/// Centralized font size definitions
enum AppFontSize {
    /// Extra large icons (onboarding, empty states)
    static let iconXL: CGFloat = 48

    /// Large icons
    static let iconLarge: CGFloat = 40

    /// Extra large headers (onboarding)
    static let headerXL: CGFloat = 32

    /// Large headers
    static let headerLarge: CGFloat = 26

    /// Section headers, page titles
    static let headerSection: CGFloat = 22

    /// Large body text, subtitles
    static let bodyLarge: CGFloat = 18

    /// Standard body text, primary content
    static let bodyStandard: CGFloat = 14

    /// Medium body text, primary content
    static let bodySmall: CGFloat = 12

    /// Captions, small labels
    static let caption: CGFloat = 10
}

// MARK: - App Fonts

/// Pre-configured font styles for common use cases
enum AppFont {

    // MARK: - Headers

    /// Extra large header (onboarding main title), bold rounded
    static let headerXL = Font.system(size: AppFontSize.headerXL, weight: .bold, design: .rounded)
    /// Large header, bold rounded
    static let headerLarge = Font.system(size: AppFontSize.headerLarge, weight: .bold, design: .rounded)
    /// Section header, bold rounded
    static let headerSection = Font.system(size: AppFontSize.headerSection, weight: .bold, design: .rounded)

    // MARK: - Body Text

    /// Large body
    static let bodyLarge = Font.system(size: AppFontSize.bodyLarge)
    /// Large body semibold
    static let bodyLargeSemibold = Font.system(size: AppFontSize.bodyLarge, weight: .semibold)
    /// Primary body (activity names), semibold
    static let bodyPrimary = Font.system(size: AppFontSize.bodyStandard, weight: .semibold)
    /// Primary body medium
    static let bodyPrimaryMedium = Font.system(size: AppFontSize.bodyStandard, weight: .medium)

    /// Standard body
    static let bodyStandard = Font.system(size: AppFontSize.bodyStandard)
    /// Standard body medium
    static let bodyStandardMedium = Font.system(size: AppFontSize.bodyStandard, weight: .medium)
    /// Standard body semibold
    static let bodyStandardSemibold = Font.system(size: AppFontSize.bodyStandard, weight: .semibold)

    /// Small body
    static let bodySmall = Font.system(size: AppFontSize.bodySmall)
    /// Standard body medium
    static let bodySmallMedium = Font.system(size: AppFontSize.bodySmall, weight: .medium)
    /// Standard body semibold
    static let bodySmallSemibold = Font.system(size: AppFontSize.bodySmall, weight: .semibold)

    /// Caption semibold
    static let bodyCaptionSemibold = Font.system(size: AppFontSize.caption, weight: .semibold)

    // MARK: - Captions

    /// Caption text
    static let caption = Font.system(size: AppFontSize.caption)
    /// Caption medium
    static let captionMedium = Font.system(size: AppFontSize.caption, weight: .medium)
    /// Caption semibold
    static let captionSemibold = Font.system(size: AppFontSize.caption, weight: .semibold)

    // MARK: - Badges

    /// Badge text, medium
    static let badge = Font.system(size: AppFontSize.caption, weight: .medium)
    /// Badge text compact, medium
    static let badgeCompact = Font.system(size: AppFontSize.caption, weight: .medium)
    /// Priority badge, bold rounded
    static let priorityBadge = Font.system(size: AppFontSize.caption, weight: .bold, design: .rounded)

    // MARK: - Buttons

    /// Button text large, semibold
    static let buttonLarge = Font.system(size: AppFontSize.bodyLarge, weight: .semibold)
    /// Button text standard, semibold
    static let buttonStandard = Font.system(size: AppFontSize.bodyStandard, weight: .semibold)
    /// Button text small, semibold
    static let buttonSmall = Font.system(size: AppFontSize.caption, weight: .semibold)

    // MARK: - Stats

    /// Large stat value, bold rounded
    static let statLarge = Font.system(size: AppFontSize.headerSection, weight: .bold, design: .rounded)
    /// Medium stat value, bold rounded
    static let statMedium = Font.system(size: AppFontSize.bodyStandard, weight: .bold, design: .rounded)
}

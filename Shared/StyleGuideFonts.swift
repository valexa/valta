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
/// Optimized scale: 10, 14, 18, 22, 26, 32, 40, 48 (min 4pt steps)
enum AppFontSize {
    // MARK: - Icon Sizes
    
    /// Extra large icons (onboarding, empty states) - 48pt
    static let iconXL: CGFloat = 48
    /// Large icons (onboarding headers) - 40pt
    static let iconLarge: CGFloat = 40
    /// Medium large icons (app icons) - 40pt
    static let iconMedium: CGFloat = 40
    /// Standard icons (section icons) - 26pt
    static let iconStandard: CGFloat = 26
    /// Notification/alert icons - 22pt
    static let iconNotification: CGFloat = 22
    /// Action button icons - 18pt
    static let iconAction: CGFloat = 18
    /// Inline icons - 18pt
    static let iconInline: CGFloat = 18
    /// Small icons - 14pt
    static let iconSmall: CGFloat = 14
    /// Info row icons - 10pt
    static let iconInfo: CGFloat = 10
    /// Badge icons (compact) - 10pt
    static let iconBadgeCompact: CGFloat = 10
    /// Badge icons - 10pt
    static let iconBadge: CGFloat = 10
    
    // MARK: - Header Sizes
    
    /// Extra large headers (onboarding) - 32pt
    static let headerXL: CGFloat = 32
    /// Large headers (onboarding) - 26pt
    static let headerLarge: CGFloat = 26
    /// Page titles - 22pt
    static let headerPage: CGFloat = 22
    /// Section headers - 22pt
    static let headerSection: CGFloat = 22
    /// Large stat values - 22pt
    static let statLarge: CGFloat = 22
    /// Medium stat values - 18pt
    static let statMedium: CGFloat = 18
    
    // MARK: - Body Text Sizes
    
    /// Subtitle text - 18pt
    static let subtitle: CGFloat = 18
    /// Large body/section titles - 18pt
    static let bodyLarge: CGFloat = 18
    /// Activity name/primary content - 14pt
    static let bodyPrimary: CGFloat = 14
    /// Form labels, member info - 14pt
    static let bodySecondary: CGFloat = 14
    /// Standard body text - 14pt
    static let bodyStandard: CGFloat = 14
    /// Small labels, time, captions - 10pt
    static let caption: CGFloat = 10
    /// Small captions, badge text - 10pt
    static let captionSmall: CGFloat = 10
    /// Tiny labels, compact badge text - 10pt
    static let captionTiny: CGFloat = 10
}

// MARK: - App Fonts

/// Pre-configured font styles for common use cases
enum AppFont {
    
    // MARK: - Headers
    
    /// Extra large header (onboarding main title)
    static let headerXL = Font.system(size: AppFontSize.headerXL, weight: .bold, design: .rounded)
    /// Large header (section titles)
    static let headerLarge = Font.system(size: AppFontSize.headerLarge, weight: .bold, design: .rounded)
    /// Page header
    static let headerPage = Font.system(size: AppFontSize.headerPage, weight: .bold, design: .rounded)
    /// Section header
    static let headerSection = Font.system(size: AppFontSize.headerSection, weight: .bold, design: .rounded)
    
    // MARK: - Body Text
    
    /// Subtitle
    static let subtitle = Font.system(size: AppFontSize.subtitle)
    /// Large body (section titles)
    static let bodyLarge = Font.system(size: AppFontSize.bodyLarge)
    /// Large body semibold
    static let bodyLargeSemibold = Font.system(size: AppFontSize.bodyLarge, weight: .semibold)
    /// Primary body (activity names)
    static let bodyPrimary = Font.system(size: AppFontSize.bodyPrimary, weight: .semibold)
    /// Primary body medium
    static let bodyPrimaryMedium = Font.system(size: AppFontSize.bodyPrimary, weight: .medium)
    /// Secondary body (form labels)
    static let bodySecondary = Font.system(size: AppFontSize.bodySecondary)
    /// Secondary body medium
    static let bodySecondaryMedium = Font.system(size: AppFontSize.bodySecondary, weight: .medium)
    /// Secondary body semibold
    static let bodySecondarySemibold = Font.system(size: AppFontSize.bodySecondary, weight: .semibold)
    /// Standard body
    static let bodyStandard = Font.system(size: AppFontSize.bodyStandard)
    /// Standard body medium
    static let bodyStandardMedium = Font.system(size: AppFontSize.bodyStandard, weight: .medium)
    /// Standard body semibold
    static let bodyStandardSemibold = Font.system(size: AppFontSize.bodyStandard, weight: .semibold)
    
    // MARK: - Captions
    
    /// Caption text
    static let caption = Font.system(size: AppFontSize.caption)
    /// Caption medium
    static let captionMedium = Font.system(size: AppFontSize.caption, weight: .medium)
    /// Caption semibold
    static let captionSemibold = Font.system(size: AppFontSize.caption, weight: .semibold)
    /// Small caption
    static let captionSmall = Font.system(size: AppFontSize.captionSmall)
    /// Small caption medium
    static let captionSmallMedium = Font.system(size: AppFontSize.captionSmall, weight: .medium)
    /// Small caption bold
    static let captionSmallBold = Font.system(size: AppFontSize.captionSmall, weight: .bold)
    /// Tiny caption
    static let captionTiny = Font.system(size: AppFontSize.captionTiny)
    /// Tiny caption semibold
    static let captionTinySemibold = Font.system(size: AppFontSize.captionTiny, weight: .semibold)
    
    // MARK: - Badges
    
    /// Badge text (normal)
    static let badge = Font.system(size: AppFontSize.captionSmall, weight: .medium)
    /// Badge text (compact)
    static let badgeCompact = Font.system(size: AppFontSize.captionTiny, weight: .medium)
    /// Priority badge
    static let priorityBadge = Font.system(size: AppFontSize.captionSmall, weight: .bold, design: .rounded)
    /// Priority badge (compact)
    static let priorityBadgeCompact = Font.system(size: AppFontSize.captionTiny, weight: .bold, design: .rounded)
    
    // MARK: - Buttons
    
    /// Button text large
    static let buttonLarge = Font.system(size: AppFontSize.bodyLarge, weight: .semibold)
    /// Button text standard
    static let buttonStandard = Font.system(size: AppFontSize.bodyStandard, weight: .semibold)
    /// Button text small
    static let buttonSmall = Font.system(size: AppFontSize.captionTiny, weight: .semibold)
    
    // MARK: - Stats
    
    /// Large stat value
    static let statLarge = Font.system(size: AppFontSize.statLarge, weight: .bold, design: .rounded)
    /// Medium stat value
    static let statMedium = Font.system(size: AppFontSize.statMedium, weight: .bold, design: .rounded)
}

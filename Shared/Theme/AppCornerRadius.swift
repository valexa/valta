//
//  AppCornerRadius.swift
//  Shared
//  Semantic corner radius scale
//
//  Centralized corner radius definitions for the Live Team Activities apps.
//  All corner radius values should be defined here.
//
//  Created by vlad on 2025-12-18.
//

import SwiftUI

// MARK: - App Corner Radius

/// Centralized corner radius definitions for consistent rounding throughout the app
enum AppCornerRadius {

    // MARK: - Base Corner Radius Scale

    /// 4pt - Extra small radius (badges, compact elements)
    static let xs: CGFloat = 4

    /// 6pt - Small radius (small badges, tags)
    static let sm: CGFloat = 6

    /// 8pt - Medium radius (buttons, text fields, rows)
    static let md: CGFloat = 8

    /// 12pt - Large radius (cards, sections, popovers)
    static let lg: CGFloat = 12

    /// 16pt - Extra large radius (large cards, modals)
    static let xl: CGFloat = 16
}

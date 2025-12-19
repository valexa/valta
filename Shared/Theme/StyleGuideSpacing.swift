//
//  StyleGuideSpacing.swift
//  Shared
//  Semantic spacing scale
//
//  Centralized spacing definitions for the Live Team Activities apps.
//  All padding and spacing values should be defined here.
//
//  Created by vlad on 2025-12-18.
//

import SwiftUI

// MARK: - App Spacing

/// Centralized spacing definitions for consistent padding throughout the app
enum AppSpacing {

    // MARK: - Base Spacing Scale

    /// 2pt - Minimal spacing (separator lines, tight vertical spacing)
    static let xxxs: CGFloat = 2

    /// 4pt - Very tight spacing (icon gaps, compact elements)
    static let xxs: CGFloat = 4

    /// 6pt - Extra small spacing (badge padding, small gaps)
    static let xs: CGFloat = 6

    /// 8pt - Small spacing (row padding, section gaps)
    static let sm: CGFloat = 8

    /// 10pt - Medium-small spacing (button padding, medium gaps)
    static let md: CGFloat = 10

    /// 12pt - Base spacing (standard padding, content gaps)
    static let base: CGFloat = 12

    /// 14pt - Large spacing (larger content gaps)
    static let lg: CGFloat = 14

    /// 16pt - Extra large spacing (card padding, section spacing)
    static let xl: CGFloat = 16

    /// 20pt - 2XL spacing (modal padding, large sections)
    static let xxl: CGFloat = 20

    /// 24pt - 3XL spacing (expanded content, large gaps)
    static let xxxl: CGFloat = 24

    /// 40pt - Huge spacing (onboarding, full-screen modals)
    static let huge: CGFloat = 40
}

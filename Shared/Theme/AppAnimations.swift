//
//  AppAnimations.swift
//  Shared
//
//  Centralized animation definitions for consistent motion design.
//  Part of the style guide system alongside StyleGuideColors, StyleGuideFonts, and StyleGuideSpacing.
//
//  Created by vlad on 2025-12-18.
//

import SwiftUI

// MARK: - App Animations

/// Centralized animation definitions for consistent motion throughout the app
enum AppAnimations {

    // MARK: - Durations

    /// 0.15s - Quick feedback animations (hover states, micro-interactions)
    static let durationQuick: Double = 0.15

    /// 0.2s - Standard UI transitions (state changes, filter toggles)
    static let durationStandard: Double = 0.2

    /// 0.3s - Interactive animations (expand/collapse, selections)
    static let durationInteractive: Double = 0.3

    /// 0.5s - Slow/emphasis animations (onboarding, major transitions)
    static let durationSlow: Double = 0.5

    // MARK: - EaseInOut Animations

    /// Quick easeInOut for hover states and micro-interactions
    static let easeQuick: Animation = .easeInOut(duration: durationQuick)

    /// Standard easeInOut for typical UI state changes
    static let easeStandard: Animation = .easeInOut(duration: durationStandard)

    // MARK: - Spring Animations

    /// Quick spring for button appearances and removals
    static let springQuick: Animation = .spring(response: 0.25, dampingFraction: 0.8)

    /// Interactive spring for expand/collapse and selections
    static let springInteractive: Animation = .spring(response: durationInteractive, dampingFraction: 0.7)

    /// Action spring for activity actions (start, complete, approve, reject)
    static let springAction: Animation = .spring(response: 0.35, dampingFraction: 0.9)

    /// Slow spring for onboarding and major transitions
    static let springSlow: Animation = .spring(duration: durationSlow)
}

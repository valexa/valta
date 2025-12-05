//
//  Theme.swift
//  Shared
//
//  Theme protocol and default implementation for dependency injection of colors.
//  Allows for theming, testing, and future customization without modifying models.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

// MARK: - Theme Protocol

/// Protocol defining all color accessors for the app theme
protocol AppTheme {
    // Priority colors
    func color(for priority: ActivityPriority) -> Color
    
    // Status colors
    func color(for status: ActivityStatus) -> Color
    
    // Outcome colors
    func color(for outcome: ActivityOutcome) -> Color
    
    // Action colors
    var destructive: Color { get }
    var success: Color { get }
    var warning: Color { get }
    
    // UI colors
    var avatar: Color { get }
    var shadow: Color { get }
    var statTotal: Color { get }
    
    // Gradients
    var avatarGradient: AnyGradient { get }
    var successGradient: LinearGradient { get }
}

// MARK: - Default Theme

/// Default theme implementation using AppColors
struct DefaultTheme: AppTheme {
    
    // MARK: - Priority Colors
    
    func color(for priority: ActivityPriority) -> Color {
        switch priority {
        case .p0: return AppColors.priorityP0
        case .p1: return AppColors.priorityP1
        case .p2: return AppColors.priorityP2
        case .p3: return AppColors.priorityP3
        }
    }
    
    // MARK: - Status Colors
    
    func color(for status: ActivityStatus) -> Color {
        switch status {
        case .running: return AppColors.statusRunning
        case .completed: return AppColors.statusCompleted
        case .canceled: return AppColors.statusCanceled
        case .managerPending: return AppColors.statusManagerPending
        case .teamMemberPending: return AppColors.statusTeamMemberPending
        }
    }
    
    // MARK: - Outcome Colors
    
    func color(for outcome: ActivityOutcome) -> Color {
        switch outcome {
        case .ahead: return AppColors.outcomeAhead
        case .jit: return AppColors.outcomeJIT
        case .overrun: return AppColors.outcomeOverrun
        }
    }
    
    // MARK: - Action Colors
    
    var destructive: Color { AppColors.destructive }
    var success: Color { AppColors.success }
    var warning: Color { AppColors.warning }
    
    // MARK: - UI Colors
    
    var avatar: Color { AppColors.avatar }
    var shadow: Color { AppColors.shadow }
    var statTotal: Color { AppColors.statTotal }
    
    // MARK: - Gradients
    
    var avatarGradient: AnyGradient { AppColors.avatar.gradient }
    var successGradient: LinearGradient { AppGradients.success }
}

// MARK: - Shared Theme Instance

/// Global shared theme instance for convenience
/// Use environment injection in views when possible
let appTheme: AppTheme = DefaultTheme()

// MARK: - Environment Key

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = DefaultTheme()
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Sets the theme for this view and its descendants
    func theme(_ theme: AppTheme) -> some View {
        environment(\.theme, theme)
    }
}

// MARK: - Model Extensions (Theme-aware)

extension ActivityPriority {
    /// Get color using theme (preferred over direct color property)
    func color(using theme: AppTheme) -> Color {
        theme.color(for: self)
    }
}

extension ActivityStatus {
    /// Get color using theme (preferred over direct color property)
    func color(using theme: AppTheme) -> Color {
        theme.color(for: self)
    }
}

extension ActivityOutcome {
    /// Get color using theme (preferred over direct color property)
    func color(using theme: AppTheme) -> Color {
        theme.color(for: self)
    }
}

extension Activity {
    /// Returns the display color based on status, priority, outcome, and special rules
    /// Uses the provided theme for color resolution
    func displayColor(using theme: AppTheme) -> Color {
        // For pending statuses, always use the status color (not outcome color)
        if status == .managerPending {
            return theme.color(for: .managerPending)
        }
        if status == .teamMemberPending {
            return theme.color(for: .teamMemberPending)
        }
        
        // Exception: For p0 activities if outcome is jit (on-time), color is red
        if priority == .p0, let outcome = outcome, outcome == .jit {
            return theme.destructive
        }
        
        // For completed activities, show outcome color
        if let outcome = outcome {
            return theme.color(for: outcome)
        }
        
        return theme.color(for: status)
    }
}


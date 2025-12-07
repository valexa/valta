//
//  ButtonStyles.swift
//  Shared
//
//  Reusable button styles and modifiers.
//
//  Created by vlad on 2025-12-05.
//

import SwiftUI

// MARK: - Onboarding Button Modifier

/// Applies the standard onboarding button styling (Glass Prominent, Large Control Size)
struct OnboardingButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(.black)
    }
}

extension View {
    /// Applies the standard onboarding button styling
    func onboardingButton() -> some View {
        modifier(OnboardingButtonStyle())
    }
}

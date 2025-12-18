//
//  CompletionButton.swift
//  Shared
//
//  A simplified reusable button component with pre-styled variants.
//  All progress handling, animations, and non-essential functionality removed.
//
//  Created by vlad on 2025-12-04.
//

import SwiftUI

struct CompletionButton<Label: View>: View {
    var role: ButtonRole?
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    init(
        role: ButtonRole? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.role = role
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(role: role, action: action) {
            label()
        }
    }
}

// MARK: - Pre-styled Variants

/// Start button for beginning an activity (blue/running tint)
struct StartButton: View {
    let action: () -> Void

    var body: some View {
        CompletionButton(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                Image(symbol: AppSymbols.play)
                    .font(AppFont.caption)
                Text("Start")
                    .font(AppFont.captionSemibold)
            }
            .foregroundColor(.white)
        }
        .buttonStyle(.glassProminent)
        .tint(AppColors.statusRunning.opacity(0.25))
    }
}

/// Complete button for requesting completion review (magenta/manager pending tint)
struct CompleteButton: View {
    let action: () -> Void

    var body: some View {
        CompletionButton(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                Image(symbol: AppSymbols.checkmark)
                    .font(AppFont.captionBold)
                Text("Complete")
                    .font(AppFont.captionSemibold)
            }
            .foregroundColor(.white)
        }
        .buttonStyle(.glassProminent)
        .tint(AppColors.statusManagerPending.opacity(0.25))
    }
}

/// Approve button for manager approval (green/completed tint)
struct ApproveButton: View {
    let action: () -> Void

    var body: some View {
        CompletionButton(role: .confirm, action: action) {
            Text("Approve")
        }
        .buttonStyle(.glass)
        .tint(AppColors.statusCompleted)
    }
}

/// Reject button for manager rejection (blue/running tint - returns to running)
struct RejectButton: View {
    let action: () -> Void

    var body: some View {
        CompletionButton(role: .destructive, action: action) {
            Text("Reject")
        }
        .buttonStyle(.glass)
        .tint(AppColors.statusRunning)
    }
}

/// Approve All button for bulk approval in toolbar
struct ApproveAllButton: View {
    let action: () -> Void

    var body: some View {
        CompletionButton(role: .confirm, action: action) {
            Text("Approve All")
        }
        .buttonStyle(.glassProminent)
        .tint(AppColors.statusCompleted)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        StartButton { print("Start") }
        CompleteButton { print("Complete") }
        ApproveButton { print("Approve") }
        RejectButton { print("Reject") }
        ApproveAllButton { print("Approve All") }

        Divider()

        // Custom usage
        CompletionButton(action: { print("Custom") }) {
            Text("Custom Button")
        }
        .buttonStyle(.borderedProminent)
    }
    .padding()
}

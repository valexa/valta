//
//  CompletionButton.swift
//  Shared
//
//  A simplified reusable button component.
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

// MARK: - Preview

#Preview {
    VStack {
        CompletionButton(action: { print("Action") }) {
            Text("Simple Button")
        }
        .buttonStyle(.borderedProminent)

        CompletionButton(role: .destructive, action: { print("Delete") }) {
            Text("Delete")
        }
        .buttonStyle(.bordered)
    }
    .padding()
}

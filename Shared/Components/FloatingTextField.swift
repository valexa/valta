//
//  FloatingTextField.swift
//  valta
//
//  A text field with a floating placeholder label that animates
//  above when the field is focused or has content.
//
//  Created by vlad on 2025-10-16.
//

import SwiftUI

// MARK: - Floating Text Field

struct FloatingTextField: View {
    let title: String
    @Binding var text: String
    var error: String = ""
    var isMultiline: Bool = false
    var minHeight: CGFloat = 44

    @FocusState private var isFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var isFloating: Bool {
        isFocused || !text.isEmpty
    }

    private var borderColor: Color {
        if !error.isEmpty {
            return .red
        }
        return isFocused ? .accentColor : Color(NSColor.separatorColor)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.05)
        : Color(NSColor.textBackgroundColor)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
            ZStack(alignment: .topLeading) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
                    )

                // Floating label
                Text(title)
                    .font(isFloating ? .caption : .body)
                    .foregroundColor(isFocused ? .accentColor : .secondary)
                    .padding(.leading, AppSpacing.base)
                    .padding(.top, isFloating ? AppSpacing.sm : (isMultiline ? AppSpacing.xl : AppSpacing.xxl))
                    .animation(AppAnimations.easeQuick, value: isFloating)

                // Text input
                TextEditor(text: $text)
                    .font(.body)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.top, AppSpacing.xxxl)
                    .padding(.bottom, AppSpacing.sm)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($isFocused)
                    .autocorrectionDisabled(false)
                    .lineLimit(isMultiline ? nil : 1)
            }
            .frame(minHeight: isMultiline ? max(minHeight, 80) : minHeight)
            .onTapGesture {
                isFocused = true
            }

            // Error message
            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, AppSpacing.xxs)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppAnimations.easeQuick, value: error.isEmpty)
    }
}

// MARK: - Preview

#Preview("Empty") {
    VStack(spacing: 16) {
        FloatingTextField(title: "Activity Name", text: .constant(""))
        FloatingTextField(title: "Description", text: .constant(""), isMultiline: true)
    }
    .padding()
    .frame(width: 400)
}

#Preview("Filled") {
    VStack(spacing: 16) {
        FloatingTextField(title: "Activity Name", text: .constant("Review PR"))
        FloatingTextField(title: "Description", text: .constant("Check the latest changes"), isMultiline: true)
    }
    .padding()
    .frame(width: 400)
}

#Preview("With Error") {
    VStack(spacing: 16) {
        FloatingTextField(title: "Activity Name", text: .constant("X"), error: "Name too short")
        FloatingTextField(title: "Description", text: .constant(""), error: "Required field", isMultiline: true)
    }
    .padding()
    .frame(width: 400)
}

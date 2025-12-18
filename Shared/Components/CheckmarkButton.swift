//
//  CheckmarkButton.swift
//  valta
//
//  Created by vlad on 10/12/2025.
//

import SwiftUI

struct CheckmarkButton: View {
    var isSelected: Bool = true
    var placeholder: Bool = true

    var body: some View {
        if !placeholder, !isSelected {
            EmptyView()
        } else {
            button
        }
    }

    var button: some View {
        Button(action: {}) {
            if isSelected {
                Image(symbol: AppSymbols.checkmark)
                    .font(.system(size: AppFontSize.bodyStandard, weight: .bold))
            } else {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 17, height: 17)
            }
        }
        .buttonStyle(.glassProminent)
        .frame(width: 14, height: 14)
        .tint(.blue)
        .disabled(!isSelected)
    }
}

// MARK: - Preview

#Preview {
    List {
        CheckmarkButton(isSelected: true)
            .padding()
        CheckmarkButton(isSelected: false, placeholder: false)
            .padding()
        CheckmarkButton(isSelected: false)
            .padding()
    }
}

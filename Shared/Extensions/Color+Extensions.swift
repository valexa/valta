//
//  Color+Extensions.swift
//  Shared
//
//  Created by vlad on 2026-01-25.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

extension Color {
    /// Mixes the receiver with another color by a given amount (0.0 - 1.0)
    /// - Parameters:
    ///   - other: The color to mix with
    ///   - amount: The ratio of the other color (0.0 = all self, 1.0 = all other)
    /// - Returns: The mixed color
    func mix(with other: Color, by amount: Double = 0.5) -> Color {
        let amount = max(0, min(1, amount))
        let c1 = PlatformColor(self)
        let c2 = PlatformColor(other)

        #if os(macOS)
        if let blended = c1.blended(withFraction: amount, of: c2) {
            return Color(blended)
        }
        return self
        #else
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        guard c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else {
            return self
        }

        let r = r1 + (r2 - r1) * CGFloat(amount)
        let g = g1 + (g2 - g1) * CGFloat(amount)
        let b = b1 + (b2 - b1) * CGFloat(amount)
        let a = a1 + (a2 - a1) * CGFloat(amount)

        return Color(PlatformColor(red: r, green: g, blue: b, alpha: a))
        #endif
    }

    /// Generates a consistent color for a given character
    /// - Parameter character: The character to generate color for
    /// - Returns: A color deterministically mapped from the character
    static func from(character: Character) -> Color {
        // Uppercase to ensure case-insensitivity
        guard let upperAscii = character.uppercased().first?.asciiValue else {
            return Color(hue: 0, saturation: 0, brightness: 0.8) // Gray fallback
        }
        let ascii = Int(upperAscii)

        // Map A-Z (65-90) to 0-25
        var index: Int
        if ascii >= 65 && ascii <= 90 {
            index = ascii - 65
        } else {
            // Fallback for non-alphabet characters
            index = ascii % 26
        }

        // Map 0-25 to 0.0-1.0 hue range
        let hue = Double(index) / 26.0
        return Color(hue: hue, saturation: 0.9, brightness: 0.6)
    }
}

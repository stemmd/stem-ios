import SwiftUI
import UIKit

// MARK: - Adaptive Color Helper

extension Color {
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

extension UIColor {
    convenience init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: h).scanHexInt64(&rgb)
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Stem Color Palette

extension Color {
    static let forest = Color(light: "#2D5A3D", dark: "#2D5A3D")
    static let forestHover = Color(light: "#4A7A5C", dark: "#4A7A5C")
    static let paper = Color(light: "#F7F4EF", dark: "#1C1B18")
    static let ink = Color(light: "#1C1A17", dark: "#E8E6E0")
    static let inkMid = Color(light: "#5C5850", dark: "#9A9890")
    static let inkLight = Color(light: "#9C9890", dark: "#6A6862")
    static let surface = Color(light: "#FFFFFF", dark: "#262520")
    static let paperMid = Color(light: "#EDE9E2", dark: "#232118")
    static let paperDark = Color(light: "#DDD8CF", dark: "#2E2B26")
    static let leaf = Color(light: "#E8F0EB", dark: "#1E2A1C")
    static let leafBorder = Color(light: "#C8DECE", dark: "#2A4A30")
    static let taken = Color(light: "#8B4A3A", dark: "#C4645A")
}

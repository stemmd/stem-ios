import SwiftUI

extension Color {
    static func categoryTint(_ id: String) -> Color {
        guard let pair = categoryColorPairs[id] else { return .surface }
        return Color(light: pair.light, dark: pair.dark)
    }
}

private let categoryColorPairs: [String: (light: String, dark: String)] = [
    "cat_architecture": ("#f5ede4", "#2a2520"),
    "cat_art":          ("#f5e8ef", "#2a2025"),
    "cat_biology":      ("#e8f2e8", "#1e2a1e"),
    "cat_craft":        ("#f2ede4", "#282520"),
    "cat_design":       ("#eee8f2", "#242028"),
    "cat_economics":    ("#e8edf2", "#1e2228"),
    "cat_film":         ("#ede8f0", "#232028"),
    "cat_food":         ("#f5ede4", "#2a2520"),
    "cat_health":       ("#eaf0ea", "#1f281f"),
    "cat_history":      ("#f2ece4", "#28251e"),
    "cat_linguistics":  ("#e8eaf2", "#1e2028"),
    "cat_literature":   ("#f0ebe4", "#28241e"),
    "cat_mathematics":  ("#e4ecf2", "#1e2428"),
    "cat_music":        ("#e4eaf5", "#1e2230"),
    "cat_nature":       ("#e4f0e8", "#1e281f"),
    "cat_philosophy":   ("#ece4f2", "#241e28"),
    "cat_photography":  ("#f0ece8", "#282420"),
    "cat_physics":      ("#e4eef5", "#1e2430"),
    "cat_politics":     ("#e8eee8", "#202820"),
    "cat_psychology":   ("#f0e8f0", "#282028"),
    "cat_science":      ("#e4f0f2", "#1e2828"),
    "cat_space":        ("#e4e8f5", "#1e2030"),
    "cat_sport":        ("#f2ece4", "#28251e"),
    "cat_technology":   ("#e8eef2", "#202428"),
    "cat_urbanism":     ("#eeeae4", "#26221e"),
]

import SwiftUI

enum DS {
    // MARK: - Corner Radii
    enum Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 20
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 32
    }

    // MARK: - Animation
    enum Animation {
        static let quick: SwiftUI.Animation = .easeOut(duration: 0.15)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.25)
    }

    // MARK: - Font Sizes
    enum FontSize {
        static let tiny: CGFloat = 10
        static let caption: CGFloat = 11
        static let small: CGFloat = 13
        static let body: CGFloat = 14
        static let bodyLarge: CGFloat = 15
        static let heading: CGFloat = 18
        static let headingLarge: CGFloat = 20
        static let title: CGFloat = 24
        static let hero: CGFloat = 28
    }
}

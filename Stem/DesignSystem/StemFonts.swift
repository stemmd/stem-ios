import SwiftUI

extension Font {
    /// DM Serif Display — headings, page titles, accent text
    static func heading(_ size: CGFloat) -> Font {
        .custom("DMSerifDisplay-Regular", size: size)
    }

    /// DM Sans — body copy, navigation, form labels
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .semibold: name = "DMSans-SemiBold"
        case .medium:   name = "DMSans-Medium"
        default:        name = "DMSans-Regular"
        }
        return .custom(name, size: size)
    }

    /// DM Mono — metadata, usernames, timestamps, domains
    static func mono(_ size: CGFloat) -> Font {
        .custom("DMMono-Regular", size: size)
    }
}

import UIKit

enum Haptic {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
    case selection

    // Convenience presets
    static let follow = Haptic.impact(.light)
    static let saved = Haptic.notification(.success)
    static let deleted = Haptic.notification(.warning)
    static let refresh = Haptic.impact(.soft)
    static let toggle = Haptic.selection
    static let error = Haptic.notification(.error)

    static func play(_ haptic: Haptic) {
        switch haptic {
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        case .notification(let type):
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
}

import SwiftUI

struct FollowButton: View {
    let isFollowing: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.play(.follow)
            action()
        } label: {
            Text(isFollowing ? "Following" : "Follow")
                .font(.body(DS.FontSize.small, weight: .medium))
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 6)
                .background(isFollowing ? Color.clear : Color.forest)
                .foregroundStyle(isFollowing ? Color.forest : .white)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.forest, lineWidth: 1)
                )
        }
        .animation(DS.Animation.quick, value: isFollowing)
    }
}

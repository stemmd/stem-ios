import SwiftUI

struct UserCard: View {
    let user: User
    var isFollowing: Bool? = nil
    var onFollowToggle: (() -> Void)? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        let content = HStack(spacing: DS.Spacing.md) {
            AvatarView(
                url: user.avatarUrl,
                name: user.displayName ?? user.username,
                size: 44
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName ?? user.username)
                    .font(.body(DS.FontSize.bodyLarge, weight: .semibold))
                    .foregroundStyle(Color.ink)

                Text("@\(user.username)")
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkMid)

                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.body(DS.FontSize.small))
                        .foregroundStyle(Color.inkMid)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let following = isFollowing, let toggle = onFollowToggle {
                FollowButton(isFollowing: following, action: toggle)
            }
        }
        .padding(.vertical, DS.Spacing.sm)
        .contentShape(Rectangle())

        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(.plain)
        } else {
            content
        }
    }
}

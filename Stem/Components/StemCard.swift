import SwiftUI

struct StemCard: View {
    let stem: Stem
    var showAuthor: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            if let emoji = stem.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 28))
            }

            Text(stem.title)
                .font(.heading(DS.FontSize.headingLarge))
                .foregroundStyle(Color.ink)
                .lineLimit(2)

            if let description = stem.description, !description.isEmpty {
                Text(description)
                    .font(.body(DS.FontSize.small))
                    .foregroundStyle(Color.inkMid)
                    .lineLimit(2)
            }

            HStack(spacing: DS.Spacing.sm) {
                if let count = stem.artifactCount {
                    Text(count == 1 ? "1 artifact" : "\(count) artifacts")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.inkLight)
                }

                if showAuthor, let username = stem.username {
                    Text("@\(username)")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.inkLight)
                }

                if stem.visibility != .public {
                    Text(stem.visibility == .private ? "🔒" : "👥")
                        .font(.system(size: 10))
                }
            }
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .stemCard(tint: Color.categoryTint(stem.primaryCategory ?? ""))
    }
}

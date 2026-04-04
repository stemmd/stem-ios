import SwiftUI

struct FeedGroupCard: View {
    let stemTitle: String
    let stemEmoji: String?
    let stemSlug: String
    let stemUsername: String
    let stemCategory: String?
    let finds: [Find]
    var onStemTap: (() -> Void)? = nil
    var onFindTap: ((Find) -> Void)? = nil
    var onAuthorTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { onStemTap?() }) {
                HStack(spacing: DS.Spacing.sm) {
                    if let emoji = stemEmoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 18))
                    }
                    Text(stemTitle)
                        .font(.heading(DS.FontSize.heading))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)

                    Spacer()

                    Button(action: { onAuthorTap?() }) {
                        Text("@\(stemUsername)")
                            .font(.mono(DS.FontSize.caption))
                            .foregroundStyle(Color.inkMid)
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.sm)
            }
            .buttonStyle(.plain)

            // Find count + share
            HStack {
                Text("\(finds.count) finds")
                    .font(.mono(DS.FontSize.tiny))
                    .foregroundStyle(Color.inkLight)

                Spacer()

                ShareLink(item: URL(string: "https://stem.md/\(stemUsername)/\(stemSlug)")!) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkLight)
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.sm)

            // Finds list
            ForEach(finds) { find in
                FindCard(find: find, compact: true) {
                    onFindTap?(find)
                }
                if find.id != finds.last?.id {
                    Divider()
                        .padding(.horizontal, DS.Spacing.md)
                }
            }

            Spacer().frame(height: DS.Spacing.sm)
        }
        .stemCard(tint: Color.categoryTint(stemCategory ?? ""))
    }
}

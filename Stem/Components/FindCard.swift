import SwiftUI

struct FindCard: View {
    let find: Find
    var compact: Bool = false
    var onTap: (() -> Void)? = nil

    private var domain: String { find.url.domainFromURL }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: compact ? 4 : DS.Spacing.sm) {
                if !compact, let imageUrl = find.imageUrl, !imageUrl.isEmpty,
                   let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .clipped()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                }

                HStack(spacing: 6) {
                    if let faviconUrl = find.faviconUrl, !faviconUrl.isEmpty,
                       let url = URL(string: faviconUrl) {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFit()
                            } else {
                                Color.paperMid
                            }
                        }
                        .frame(width: 14, height: 14)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }

                    Text(find.title ?? domain)
                        .font(.body(compact ? DS.FontSize.body : DS.FontSize.bodyLarge, weight: .medium))
                        .foregroundStyle(Color.ink)
                        .lineLimit(compact ? 1 : 2)

                    Spacer()

                    Text(domain)
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.inkLight)
                        .lineLimit(1)
                }

                if !compact, let note = find.note, !note.isEmpty {
                    Text(note)
                        .font(.body(DS.FontSize.small))
                        .foregroundStyle(Color.inkMid)
                        .italic()
                        .lineLimit(3)
                }
            }
            .padding(compact ? DS.Spacing.sm : DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension String {
    var domainFromURL: String {
        guard let url = URL(string: self), let host = url.host() else {
            return self
        }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}

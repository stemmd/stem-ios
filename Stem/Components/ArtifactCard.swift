import SwiftUI

/// Compact row representation of an artifact.
/// Used in the overview list inside a stem, and inside the feed.
struct ArtifactCard: View {
    let artifact: Artifact
    var compact: Bool = false
    var onTap: (() -> Void)? = nil

    private var domain: String { artifact.url.domainFromURL }

    var body: some View {
        Button(action: { onTap?() }) {
            if artifact.isNote {
                noteBody
            } else {
                linkBody
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var linkBody: some View {
        VStack(alignment: .leading, spacing: compact ? 4 : DS.Spacing.sm) {
            if !compact, let imageUrl = artifact.imageUrl, !imageUrl.isEmpty,
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
                if let faviconUrl = artifact.faviconUrl, !faviconUrl.isEmpty,
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

                Text(artifact.title ?? domain)
                    .font(.body(compact ? DS.FontSize.body : DS.FontSize.bodyLarge, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(compact ? 1 : 2)

                Spacer()

                Text(domain)
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkLight)
                    .lineLimit(1)
            }

            if !compact, let note = artifact.noteContent, !note.isEmpty {
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

    @ViewBuilder
    private var noteBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "text.quote")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.forest)
                if let title = artifact.title, !title.isEmpty {
                    Text(title)
                        .font(.body(DS.FontSize.body, weight: .medium))
                        .foregroundStyle(Color.ink)
                        .lineLimit(1)
                } else {
                    Text("Note")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.inkLight)
                }
                Spacer()
            }

            if let note = artifact.noteContent, !note.isEmpty {
                Text(note)
                    .font(.body(DS.FontSize.body))
                    .foregroundStyle(Color.inkMid)
                    .lineLimit(compact ? 2 : 4)
            }
        }
        .padding(compact ? DS.Spacing.sm : DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
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

import SwiftUI

/// The "whole plant" view. Always visible while the user is inside a stem.
/// Nodes and loose artifacts render as compact rows along a left rail.
/// Tapping a row "pulls it closer" — the focus layer in StemDetailView takes over.
struct StemOverviewView: View {
    @Bindable var vm: StemDetailViewModel
    @Binding var focused: FocusTarget?
    let namespace: Namespace.ID
    let onOpenAddArtifact: () -> Void

    var body: some View {
        let rootNodes = vm.rootNodes
        let rootArtifacts = vm.rootArtifacts
        let hasAny = !rootNodes.isEmpty || !rootArtifacts.isEmpty

        if !hasAny {
            EmptyStateView(
                icon: "🌱",
                title: "This stem is empty",
                message: vm.isOwner ? "Tap + to plant your first artifact" : nil
            )
            .padding(.top, DS.Spacing.xl)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(rootNodes.enumerated()), id: \.element.id) { index, node in
                    OverviewRow(isFirst: index == 0, isLast: false) {
                        NodeRowCard(
                            node: node,
                            artifactCount: vm.artifactCount(in: node.id),
                            subNodeCount: vm.subNodeCount(of: node.id)
                        )
                        .matchedGeometryEffect(
                            id: "node-\(node.id)",
                            in: namespace,
                            isSource: focused != .node(node.id)
                        )
                        .opacity(focused == .node(node.id) ? 0 : 1)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                focused = .node(node.id)
                            }
                            Haptic.play(.toggle)
                        }
                    }
                }

                ForEach(Array(rootArtifacts.enumerated()), id: \.element.id) { index, artifact in
                    OverviewRow(
                        isFirst: rootNodes.isEmpty && index == 0,
                        isLast: index == rootArtifacts.count - 1
                    ) {
                        ArtifactRowCard(artifact: artifact)
                            .matchedGeometryEffect(
                                id: "artifact-\(artifact.id)",
                                in: namespace,
                                isSource: focused != .artifact(artifact.id)
                            )
                            .opacity(focused == .artifact(artifact.id) ? 0 : 1)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                                    focused = .artifact(artifact.id)
                                }
                                Haptic.play(.toggle)
                            }
                    }
                }
            }
            .padding(.horizontal, DS.Spacing.md)
        }
    }
}

// MARK: - Row with left rail

/// One row of the overview: a left rail segment with a junction and a horizontal
/// connector, followed by content.
struct OverviewRow<Content: View>: View {
    let isFirst: Bool
    let isLast: Bool
    @ViewBuilder let content: () -> Content

    private let railColumnWidth: CGFloat = 40
    private let dotSize: CGFloat = 10

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ZStack(alignment: .top) {
                // Continuous rail segment
                HStack {
                    Spacer().frame(width: (railColumnWidth - 2) / 2)
                    Rectangle()
                        .fill(Color.leafBorder)
                        .frame(width: 2)
                        .padding(.top, isFirst ? 22 : 0)
                        .padding(.bottom, isLast ? 22 : 0)
                    Spacer()
                }

                // Junction + horizontal connector
                HStack(spacing: 0) {
                    Spacer().frame(width: (railColumnWidth - dotSize) / 2)
                    Circle()
                        .fill(Color.forest)
                        .frame(width: dotSize, height: dotSize)
                    Rectangle()
                        .fill(Color.leafBorder)
                        .frame(height: 2)
                }
                .padding(.top, 22) // approx card vertical center for compact rows
            }
            .frame(width: railColumnWidth + 12)

            content()
                .padding(.vertical, 6)
                .padding(.trailing, 4)
        }
    }
}

// MARK: - Compact cards for the overview

struct NodeRowCard: View {
    let node: Node
    let artifactCount: Int
    let subNodeCount: Int

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            if let emoji = node.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(node.title)
                    .font(.heading(DS.FontSize.heading))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkMid)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkLight)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.leaf)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .strokeBorder(Color.leafBorder, lineWidth: 1)
        )
    }

    private var subtitle: String {
        var parts: [String] = []
        if artifactCount > 0 {
            parts.append(artifactCount == 1 ? "1 artifact" : "\(artifactCount) artifacts")
        }
        if subNodeCount > 0 {
            parts.append(subNodeCount == 1 ? "1 sub-topic" : "\(subNodeCount) sub-topics")
        }
        return parts.isEmpty ? "empty" : parts.joined(separator: " · ")
    }
}

struct ArtifactRowCard: View {
    let artifact: Artifact

    private var domain: String { artifact.url.domainFromURL }

    var body: some View {
        if artifact.isNote {
            noteRow
        } else {
            linkRow
        }
    }

    @ViewBuilder
    private var linkRow: some View {
        HStack(spacing: DS.Spacing.sm) {
            if let faviconUrl = artifact.faviconUrl, !faviconUrl.isEmpty,
               let url = URL(string: faviconUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.paperMid
                    }
                }
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkLight)
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(artifact.title ?? domain)
                    .font(.body(DS.FontSize.bodyLarge, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(domain)
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkLight)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .strokeBorder(Color.paperDark, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var noteRow: some View {
        HStack(alignment: .top, spacing: DS.Spacing.sm) {
            Image(systemName: "text.quote")
                .font(.system(size: 14))
                .foregroundStyle(Color.forest)
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 4) {
                if let title = artifact.title, !title.isEmpty {
                    Text(title)
                        .font(.body(DS.FontSize.bodyLarge, weight: .medium))
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                if let note = artifact.noteContent, !note.isEmpty {
                    Text(note)
                        .font(.body(DS.FontSize.body))
                        .foregroundStyle(Color.inkMid)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.medium)
                .strokeBorder(Color.paperDark, lineWidth: 1)
        )
    }
}

import SwiftUI

/// The leaf that's been "pulled closer." Renders over the dimmed stem.
/// Artifact focus shows a large reader-like card with domain, image, note, and an open-link button.
/// Node focus shows a mini-stem: the node's direct children, each tappable to transfer focus.
struct StemFocusLayer: View {
    let target: FocusTarget
    @Bindable var vm: StemDetailViewModel
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    let onOpenURL: (URL) -> Void
    let onTransferFocus: (FocusTarget) -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        card
            .matchedGeometryEffect(id: target.matchedID, in: namespace, isSource: true)
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only register downward drag for dismissal.
                        dragOffset = max(0, value.translation.height)
                    }
                    .onEnded { value in
                        if value.translation.height > 120 {
                            onDismiss()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
    }

    @ViewBuilder
    private var card: some View {
        switch target {
        case .artifact(let id):
            if let artifact = vm.artifact(id: id) {
                FocusedArtifactCard(
                    artifact: artifact,
                    onDismiss: onDismiss,
                    onOpenURL: onOpenURL
                )
            } else {
                missingCard
            }
        case .node(let id):
            if let node = vm.node(id: id) {
                FocusedNodeCard(
                    node: node,
                    vm: vm,
                    namespace: namespace,
                    onDismiss: onDismiss,
                    onTransferFocus: onTransferFocus
                )
            } else {
                missingCard
            }
        }
    }

    private var missingCard: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("This doesn't seem to exist anymore")
                .font(.body(DS.FontSize.body))
                .foregroundStyle(Color.inkMid)
            Button("Close", action: onDismiss)
                .foregroundStyle(Color.forest)
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
    }
}

// MARK: - Focused artifact

struct FocusedArtifactCard: View {
    let artifact: Artifact
    let onDismiss: () -> Void
    let onOpenURL: (URL) -> Void

    private var domain: String { artifact.url.domainFromURL }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Close bar
            HStack {
                // Drag handle hint
                Capsule()
                    .fill(Color.paperDark)
                    .frame(width: 36, height: 4)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.inkMid)
                        .padding(10)
                        .background(Color.paperMid.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
            .overlay(alignment: .center) {
                Capsule()
                    .fill(Color.paperDark)
                    .frame(width: 36, height: 4)
                    .padding(.top, DS.Spacing.sm)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    if artifact.isNote {
                        noteContent
                    } else {
                        linkContent
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .strokeBorder(Color.paperDark, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 30, y: 10)
    }

    @ViewBuilder
    private var linkContent: some View {
        if let imageUrl = artifact.imageUrl, !imageUrl.isEmpty, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.paperMid)
                        .frame(height: 180)
                }
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        }

        HStack(spacing: 8) {
            if let faviconUrl = artifact.faviconUrl, !faviconUrl.isEmpty,
               let url = URL(string: faviconUrl) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else {
                        Color.paperMid
                    }
                }
                .frame(width: 16, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            Text(domain)
                .font(.mono(DS.FontSize.small))
                .foregroundStyle(Color.inkMid)
        }

        Text(artifact.title ?? domain)
            .font(.heading(DS.FontSize.title))
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)

        if let desc = artifact.description, !desc.isEmpty {
            Text(desc)
                .font(.body(DS.FontSize.bodyLarge))
                .foregroundStyle(Color.inkMid)
                .fixedSize(horizontal: false, vertical: true)
        }

        if let note = artifact.noteContent, !note.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Note")
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.forest)
                Text(note)
                    .font(.body(DS.FontSize.bodyLarge))
                    .foregroundStyle(Color.ink)
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.leaf)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
        }

        if let url = URL(string: artifact.url) {
            Button {
                onOpenURL(url)
                Analytics.track("open_link")
            } label: {
                HStack {
                    Image(systemName: "safari")
                    Text("Open link")
                        .font(.body(DS.FontSize.bodyLarge, weight: .medium))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Color.white)
                .padding(.horizontal, DS.Spacing.md)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.forest)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            }
            .padding(.top, DS.Spacing.xs)
        }
    }

    @ViewBuilder
    private var noteContent: some View {
        if let title = artifact.title, !title.isEmpty {
            Text(title)
                .font(.heading(DS.FontSize.title))
                .foregroundStyle(Color.ink)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("Note")
                .font(.mono(DS.FontSize.caption))
                .foregroundStyle(Color.forest)
        }

        if let note = artifact.noteContent, !note.isEmpty {
            Text(note)
                .font(.body(DS.FontSize.bodyLarge))
                .foregroundStyle(Color.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text("(Empty note)")
                .font(.body(DS.FontSize.body))
                .foregroundStyle(Color.inkLight)
                .italic()
        }
    }
}

// MARK: - Focused node

struct FocusedNodeCard: View {
    let node: Node
    @Bindable var vm: StemDetailViewModel
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    let onTransferFocus: (FocusTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Capsule()
                    .fill(Color.paperDark)
                    .frame(width: 36, height: 4)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.inkMid)
                        .padding(10)
                        .background(Color.paperMid.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.top, DS.Spacing.sm)
            .overlay(alignment: .center) {
                Capsule()
                    .fill(Color.paperDark)
                    .frame(width: 36, height: 4)
                    .padding(.top, DS.Spacing.sm)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    nodeHeader
                    innerOverview
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.top, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.leaf)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.large)
                .strokeBorder(Color.leafBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 30, y: 10)
    }

    @ViewBuilder
    private var nodeHeader: some View {
        if let emoji = node.emoji, !emoji.isEmpty {
            Text(emoji)
                .font(.system(size: 44))
        }
        Text(node.title)
            .font(.heading(DS.FontSize.title))
            .foregroundStyle(Color.ink)
            .fixedSize(horizontal: false, vertical: true)

        if let desc = node.description, !desc.isEmpty {
            Text(desc)
                .font(.body(DS.FontSize.bodyLarge))
                .foregroundStyle(Color.inkMid)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var innerOverview: some View {
        let subNodes = vm.childNodes(of: node.id)
        let innerArtifacts = vm.artifacts(in: node.id)

        if subNodes.isEmpty && innerArtifacts.isEmpty {
            Text("Nothing here yet")
                .font(.body(DS.FontSize.body))
                .foregroundStyle(Color.inkLight)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, DS.Spacing.md)
        } else {
            VStack(spacing: DS.Spacing.sm) {
                ForEach(subNodes, id: \.id) { child in
                    NodeRowCard(
                        node: child,
                        artifactCount: vm.artifactCount(in: child.id),
                        subNodeCount: vm.subNodeCount(of: child.id)
                    )
                    .onTapGesture {
                        onTransferFocus(.node(child.id))
                    }
                }
                ForEach(innerArtifacts, id: \.id) { artifact in
                    ArtifactRowCard(artifact: artifact)
                        .onTapGesture {
                            onTransferFocus(.artifact(artifact.id))
                        }
                }
            }
        }
    }
}

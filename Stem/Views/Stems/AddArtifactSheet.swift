import SwiftUI

struct AddArtifactSheet: View {
    let stemId: String
    let nodeId: String?
    let onComplete: (Bool) -> Void

    init(stemId: String, nodeId: String? = nil, onComplete: @escaping (Bool) -> Void) {
        self.stemId = stemId
        self.nodeId = nodeId
        self.onComplete = onComplete
    }

    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var note = ""
    @State private var saving = false
    @State private var error: String?

    // OG metadata
    @State private var ogTitle: String?
    @State private var ogDescription: String?
    @State private var ogImage: String?
    @State private var ogFavicon: String?
    @State private var ogSourceType: String?
    @State private var fetchingOG = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    // URL input
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("URL")
                            .font(.body(DS.FontSize.small, weight: .semibold))
                            .foregroundStyle(Color.inkMid)

                        HStack {
                            TextField("Paste a link", text: $url)
                                .font(.mono(DS.FontSize.body))
                                .textContentType(.URL)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .onSubmit { fetchMetadata() }

                            if !url.isEmpty {
                                Button {
                                    fetchMetadata()
                                } label: {
                                    Image(systemName: fetchingOG ? "arrow.clockwise" : "arrow.right.circle.fill")
                                        .foregroundStyle(Color.forest)
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.small)
                                .strokeBorder(Color.paperDark, lineWidth: 1)
                        )

                        Button {
                            if let clip = UIPasteboard.general.string, clip.hasPrefix("http") {
                                url = clip
                                fetchMetadata()
                            }
                        } label: {
                            Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                                .font(.body(DS.FontSize.small))
                                .foregroundStyle(Color.forest)
                        }
                    }

                    // OG Preview
                    if let title = ogTitle {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            if let imageUrl = ogImage, let imgURL = URL(string: imageUrl) {
                                AsyncImage(url: imgURL) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 120)
                                            .clipped()
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                            }

                            Text(title)
                                .font(.body(DS.FontSize.body, weight: .medium))
                                .foregroundStyle(Color.ink)
                                .lineLimit(2)

                            if let desc = ogDescription {
                                Text(desc)
                                    .font(.body(DS.FontSize.small))
                                    .foregroundStyle(Color.inkMid)
                                    .lineLimit(2)
                            }

                            Text(url.domainFromURL)
                                .font(.mono(DS.FontSize.caption))
                                .foregroundStyle(Color.inkLight)
                        }
                        .padding(DS.Spacing.md)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.medium)
                                .strokeBorder(Color.paperDark, lineWidth: 1)
                        )
                    }

                    // Note
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Note (optional)")
                            .font(.body(DS.FontSize.small, weight: .semibold))
                            .foregroundStyle(Color.inkMid)

                        TextField("Why is this interesting?", text: $note, axis: .vertical)
                            .font(.body(DS.FontSize.body))
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Color.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.small)
                                    .strokeBorder(Color.paperDark, lineWidth: 1)
                            )
                    }

                    if let error {
                        Text(error)
                            .font(.body(DS.FontSize.small))
                            .foregroundStyle(Color.taken)
                    }
                }
                .padding(DS.Spacing.lg)
            }
            .background(Color.paper)
            .navigationTitle("Add artifact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving..." : "Save") {
                        save()
                    }
                    .disabled(url.isEmpty || !url.hasPrefix("http") || saving)
                    .foregroundStyle(Color.forest)
                }
            }
        }
    }

    private func fetchMetadata() {
        let cleanURL = url.trimmingCharacters(in: .whitespaces)
        guard cleanURL.hasPrefix("http") else { return }
        fetchingOG = true
        Task {
            do {
                let og = try await APIClient.shared.getOGMetadata(url: cleanURL)
                ogTitle = og.title
                ogDescription = og.description
                ogImage = og.image
                ogFavicon = og.favicon
                ogSourceType = og.sourceType
            } catch {}
            fetchingOG = false
        }
    }

    private func save() {
        saving = true
        error = nil
        Task {
            do {
                _ = try await APIClient.shared.addArtifact(
                    stemId: stemId,
                    body: AddArtifactBody(
                        url: url.trimmingCharacters(in: .whitespaces),
                        note: note.isEmpty ? nil : note,
                        title: ogTitle,
                        description: ogDescription,
                        sourceType: ogSourceType,
                        nodeId: nodeId
                    )
                )
                Haptic.play(.saved)
                Analytics.track("add_artifact")
                onComplete(true)
                dismiss()
            } catch {
                Haptic.play(.error)
                self.error = "Couldn't save this artifact"
                saving = false
            }
        }
    }
}

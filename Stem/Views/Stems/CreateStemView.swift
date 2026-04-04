import SwiftUI

struct CreateStemView: View {
    var onCreated: (() -> Void)? = nil

    @State private var title = ""
    @State private var description = ""
    @State private var emoji = ""
    @State private var visibility: Visibility = .public
    @State private var contributionMode: ContributionMode = .open
    @State private var selectedCategories: Set<String> = []
    @State private var saving = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What trail are you going down?", text: $title)
                        .font(.body(DS.FontSize.bodyLarge))
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(.body(DS.FontSize.body))
                        .lineLimit(3...6)
                    TextField("Emoji (optional)", text: $emoji)
                        .font(.body(DS.FontSize.body))
                }

                CategorySelectionSection(selectedCategories: $selectedCategories)

                Section {
                    VisibilityPicker(value: $visibility)
                }

                Section {
                    ContributionPicker(value: $contributionMode)
                }

                if let error {
                    Text(error)
                        .font(.body(DS.FontSize.small))
                        .foregroundStyle(Color.taken)
                }
            }
            .background(Color.paper)
            .navigationTitle("New stem")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCreated?() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Creating..." : "Create") {
                        save()
                    }
                    .font(.body(DS.FontSize.body, weight: .medium))
                    .disabled(title.trimmingCharacters(in: .whitespaces).count < 2 || selectedCategories.isEmpty || saving)
                }
            }
        }
    }

    private func save() {
        saving = true
        error = nil
        Haptic.play(.toggle)
        Task {
            do {
                _ = try await APIClient.shared.createStem(CreateStemBody(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    emoji: emoji.isEmpty ? nil : emoji,
                    visibility: visibility.rawValue,
                    contributionMode: contributionMode.rawValue,
                    categories: Array(selectedCategories)
                ))
                Haptic.play(.saved)
                Analytics.track("create_stem")
                onCreated?()
            } catch let err {
                Haptic.play(.error)
                error = err.localizedDescription
                saving = false
            }
        }
    }
}

import SwiftUI

struct EditStemView: View {
    let stem: Stem
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var emoji: String
    @State private var visibility: Visibility
    @State private var contributionMode: ContributionMode
    @State private var selectedCategories: Set<String>
    @State private var saving = false
    @State private var error: String?
    @State private var showDeleteConfirmation = false
    @State private var deleting = false

    init(stem: Stem, existingCategories: [String] = [], onSave: @escaping () -> Void) {
        self.stem = stem
        self.onSave = onSave
        _title = State(initialValue: stem.title)
        _description = State(initialValue: stem.description ?? "")
        _emoji = State(initialValue: stem.emoji ?? "")
        _visibility = State(initialValue: stem.visibility)
        _contributionMode = State(initialValue: stem.contributionMode ?? .open)
        _selectedCategories = State(initialValue: Set(existingCategories.isEmpty ? [stem.primaryCategory].compactMap { $0 } : existingCategories))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
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

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text(deleting ? "Deleting..." : "Delete this stem")
                        }
                        .font(.body(DS.FontSize.body))
                    }
                    .disabled(deleting)
                }
            }
            .navigationTitle("Edit stem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving..." : "Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).count < 2 || saving)
                        .foregroundStyle(Color.forest)
                }
            }
            .alert("Delete this stem?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { deleteStem() }
            } message: {
                Text("This will permanently delete the stem and all its finds")
            }
        }
    }

    private func save() {
        saving = true
        error = nil
        Task {
            do {
                _ = try await APIClient.shared.updateStem(id: stem.id, body: UpdateStemBody(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    emoji: emoji.isEmpty ? nil : emoji,
                    visibility: visibility.rawValue,
                    contributionMode: contributionMode.rawValue,
                    categories: Array(selectedCategories)
                ))
                Haptic.play(.saved)
                onSave()
                dismiss()
            } catch {
                Haptic.play(.error)
                self.error = "Couldn't save changes"
                saving = false
            }
        }
    }

    private func deleteStem() {
        deleting = true
        Haptic.play(.deleted)
        Task {
            do {
                _ = try await APIClient.shared.deleteStem(id: stem.id)
                onSave()
                dismiss()
            } catch {
                self.error = "Couldn't delete this stem"
                deleting = false
            }
        }
    }
}

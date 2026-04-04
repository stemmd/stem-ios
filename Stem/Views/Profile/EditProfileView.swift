import SwiftUI

struct EditProfileView: View {
    let user: User
    let onSave: (User) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String
    @State private var bio: String
    @State private var website: String
    @State private var twitter: String
    @State private var saving = false
    @State private var error: String?

    init(user: User, onSave: @escaping (User) -> Void) {
        self.user = user
        self.onSave = onSave
        _displayName = State(initialValue: user.displayName ?? "")
        _bio = State(initialValue: user.bio ?? "")
        _website = State(initialValue: user.website ?? "")
        _twitter = State(initialValue: user.twitter ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Display name")
                            .font(.body(DS.FontSize.small, weight: .semibold))
                            .foregroundStyle(Color.inkMid)
                        TextField("Your name", text: $displayName)
                            .font(.body(DS.FontSize.body))
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Bio")
                            .font(.body(DS.FontSize.small, weight: .semibold))
                            .foregroundStyle(Color.inkMid)
                        TextField("Tell people what you're into", text: $bio, axis: .vertical)
                            .font(.body(DS.FontSize.body))
                            .lineLimit(3...6)
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Website")
                            .font(.body(DS.FontSize.small, weight: .semibold))
                            .foregroundStyle(Color.inkMid)
                        TextField("https://", text: $website)
                            .font(.mono(DS.FontSize.body))
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }

                    VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                        Text("Twitter")
                            .font(.body(DS.FontSize.small, weight: .semibold))
                            .foregroundStyle(Color.inkMid)
                        TextField("@username", text: $twitter)
                            .font(.mono(DS.FontSize.body))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                if let error {
                    Text(error)
                        .font(.body(DS.FontSize.small))
                        .foregroundStyle(Color.taken)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving..." : "Save") { save() }
                        .disabled(saving)
                        .foregroundStyle(Color.forest)
                }
            }
        }
    }

    private func save() {
        saving = true
        error = nil
        Task {
            do {
                let res = try await APIClient.shared.updateProfile(body: UpdateProfileBody(
                    displayName: displayName.isEmpty ? nil : displayName,
                    bio: bio.isEmpty ? nil : bio,
                    website: website.isEmpty ? nil : website,
                    twitter: twitter.isEmpty ? nil : twitter.replacingOccurrences(of: "@", with: "")
                ))
                Haptic.play(.saved)
                onSave(res.user)
                dismiss()
            } catch {
                Haptic.play(.error)
                self.error = "Couldn't save changes"
                saving = false
            }
        }
    }
}

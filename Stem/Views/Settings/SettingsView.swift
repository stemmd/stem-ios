import SwiftUI

struct SettingsView: View {
    var currentUser: User? = nil
    @AppStorage("appearance") private var appearance = "system"
    @State private var showEditProfile = false

    var body: some View {
        List {
            if currentUser != nil {
                Section("Profile") {
                    Button {
                        showEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "person")
                    }
                }
            }

            Section("Preferences") {
                Picker(selection: $appearance) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                } label: {
                    Label("Appearance", systemImage: "paintbrush")
                }
            }

            Section("About") {
                Link(destination: URL(string: "https://stem.md/terms")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                        .foregroundStyle(Color.ink)
                }
                Link(destination: URL(string: "https://stem.md/privacy")!) {
                    Label("Privacy Policy", systemImage: "lock.shield")
                        .foregroundStyle(Color.ink)
                }
                Link(destination: URL(string: "https://stem.md/discord")!) {
                    Label("Discord Community", systemImage: "bubble.left.and.bubble.right")
                        .foregroundStyle(Color.ink)
                }
                HStack {
                    Label("Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .font(.mono(DS.FontSize.small))
                        .foregroundStyle(Color.inkLight)
                }
            }

            Section {
                Button(role: .destructive) {
                    Haptic.play(.deleted)
                    APIClient.shared.signOut()
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.paper)
        .navigationTitle("Settings")
        .sheet(isPresented: $showEditProfile) {
            if let user = currentUser {
                EditProfileView(user: user) { _ in
                    showEditProfile = false
                }
            }
        }
    }
}

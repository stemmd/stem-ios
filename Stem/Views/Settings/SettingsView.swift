import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    NavigationLink("Profile") {
                        Text("Profile settings")
                    }
                }

                Section("Preferences") {
                    NavigationLink("Notifications") {
                        Text("Notification settings")
                    }
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        APIClient.shared.token = nil
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

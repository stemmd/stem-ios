import SwiftUI

struct StemFollowerListView: View {
    let stemId: String
    let stemTitle: String
    @State private var users: [User] = []
    @State private var loading = true

    var body: some View {
        ScrollView {
            if loading {
                LoadingView()
                    .padding(.top, 40)
            } else if users.isEmpty {
                EmptyStateView(icon: "👥", title: "No followers yet")
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(users) { user in
                        NavigationLink(value: StemNavigation.profile(user.username)) {
                            UserCard(user: user)
                        }
                        .padding(.horizontal, DS.Spacing.md)
                        Divider().padding(.horizontal, DS.Spacing.md)
                    }
                }
            }
        }
        .background(Color.paper)
        .navigationTitle("Followers")
        .navigationBarTitleDisplayMode(.inline)
        .stemNavigationDestinations()
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.getStemFollowers(stemId: stemId)
            users = res.users
        } catch {}
        loading = false
    }
}

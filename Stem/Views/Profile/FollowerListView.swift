import SwiftUI

struct FollowerListView: View {
    let username: String
    @State private var selectedTab = 0
    @State private var followers: [User] = []
    @State private var following: [User] = []
    @State private var followedStems: [Stem] = []
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Followers").tag(0)
                Text("Following").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, DS.Spacing.sm)

            ScrollView {
                if loading {
                    LoadingView()
                        .padding(.top, 40)
                } else if selectedTab == 0 {
                    if followers.isEmpty {
                        EmptyStateView(icon: "👥", title: "No followers yet")
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(followers) { user in
                                NavigationLink(value: StemNavigation.profile(user.username)) {
                                    UserCard(user: user)
                                }
                                .padding(.horizontal, DS.Spacing.md)
                                Divider().padding(.horizontal, DS.Spacing.md)
                            }
                        }
                    }
                } else {
                    if following.isEmpty && followedStems.isEmpty {
                        EmptyStateView(icon: "👥", title: "Not following anyone yet")
                    } else {
                        LazyVStack(spacing: 0) {
                            if !following.isEmpty {
                                Text("People")
                                    .font(.body(DS.FontSize.small, weight: .semibold))
                                    .foregroundStyle(Color.inkMid)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, DS.Spacing.md)
                                    .padding(.vertical, DS.Spacing.sm)

                                ForEach(following) { user in
                                    NavigationLink(value: StemNavigation.profile(user.username)) {
                                        UserCard(user: user)
                                    }
                                    .padding(.horizontal, DS.Spacing.md)
                                    Divider().padding(.horizontal, DS.Spacing.md)
                                }
                            }

                            if !followedStems.isEmpty {
                                Text("Stems")
                                    .font(.body(DS.FontSize.small, weight: .semibold))
                                    .foregroundStyle(Color.inkMid)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, DS.Spacing.md)
                                    .padding(.vertical, DS.Spacing.sm)

                                ForEach(followedStems) { stem in
                                    NavigationLink(value: StemNavigation.stemDetail(stem.id)) {
                                        StemCard(stem: stem)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal, DS.Spacing.md)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.paper)
        .navigationTitle("@\(username)")
        .navigationBarTitleDisplayMode(.inline)
        .stemNavigationDestinations()
        .task { await load() }
    }

    private func load() async {
        loading = true
        async let f = APIClient.shared.getFollowers(username: username)
        async let g = APIClient.shared.getFollowing(username: username)
        do {
            let (fRes, gRes) = try await (f, g)
            followers = fRes.users
            following = gRes.users
            followedStems = gRes.stems
        } catch {}
        loading = false
    }
}

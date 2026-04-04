import SwiftUI

struct ProfileView: View {
    let username: String
    @State private var vm: ProfileViewModel

    init(username: String) {
        self.username = username
        self._vm = State(initialValue: ProfileViewModel(username: username))
    }

    var body: some View {
        ScrollView {
            if vm.loading && vm.user == nil {
                LoadingView()
                    .padding(.top, 60)
            } else if let user = vm.user {
                VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                    // Profile header
                    profileHeader(user)

                    // Stems by category
                    if vm.stems.isEmpty {
                        EmptyStateView(
                            icon: "🌿",
                            title: vm.isOwner ? "No stems yet" : "@\(username) hasn't created any stems yet",
                            message: vm.isOwner ? "Create your first stem to get started" : nil
                        )
                    } else {
                        ForEach(vm.stemsByCategory, id: \.category) { group in
                            categorySection(group.category, stems: group.stems)
                        }
                    }
                }
            } else if let error = vm.error {
                EmptyStateView(icon: "⚠️", title: "Something went wrong", message: error)
            }
        }
        .background(Color.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.isOwner {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink(destination: SettingsView(currentUser: vm.user)) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.inkMid)
                    }
                }
            }
        }
        .stemNavigationDestinations()
        .refreshable {
            await vm.load()
            Haptic.play(.refresh)
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func profileHeader(_ user: User) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.md) {
                AvatarView(
                    url: user.avatarUrl,
                    name: user.displayName ?? user.username,
                    size: 64
                )

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(user.displayName ?? user.username)
                        .font(.heading(DS.FontSize.headingLarge))
                        .foregroundStyle(Color.ink)

                    Text("@\(user.username)")
                        .font(.mono(DS.FontSize.small))
                        .foregroundStyle(Color.inkMid)
                }

                Spacer()

                if !vm.isOwner {
                    FollowButton(isFollowing: vm.isFollowing) {
                        Task { await vm.toggleFollow() }
                    }
                }
            }

            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body(DS.FontSize.body))
                    .foregroundStyle(Color.ink)
            }

            // Links
            HStack(spacing: DS.Spacing.md) {
                if let website = user.website, !website.isEmpty {
                    Link(destination: URL(string: website) ?? URL(string: "https://stem.md")!) {
                        Label(website.domainFromURL, systemImage: "globe")
                            .font(.mono(DS.FontSize.caption))
                            .foregroundStyle(Color.forest)
                    }
                }
                if let twitter = user.twitter, !twitter.isEmpty {
                    Link(destination: URL(string: "https://twitter.com/\(twitter)") ?? URL(string: "https://twitter.com")!) {
                        Label("@\(twitter)", systemImage: "at")
                            .font(.mono(DS.FontSize.caption))
                            .foregroundStyle(Color.forest)
                    }
                }
            }

            // Stats
            HStack(spacing: DS.Spacing.lg) {
                NavigationLink(value: StemNavigation.followers(username)) {
                    statView(count: vm.followerCount, label: "followers")
                }
                NavigationLink(value: StemNavigation.followers(username)) {
                    statView(count: vm.followingCount, label: "following")
                }
                statView(count: vm.stems.count, label: "stems")
            }
        }
        .padding(DS.Spacing.lg)
    }

    private func statView(count: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.body(DS.FontSize.bodyLarge, weight: .semibold))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.mono(DS.FontSize.caption))
                .foregroundStyle(Color.inkLight)
        }
    }

    @ViewBuilder
    private func categorySection(_ categoryId: String, stems: [Stem]) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            if let cat = categoryById(categoryId) {
                Text("\(cat.emoji) \(cat.name)")
                    .font(.body(DS.FontSize.small, weight: .semibold))
                    .foregroundStyle(Color.inkMid)
                    .padding(.horizontal, DS.Spacing.lg)
            }

            ForEach(stems) { stem in
                NavigationLink(value: StemNavigation.stemDetail(stem.id)) {
                    StemCard(stem: stem, showAuthor: false)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.Spacing.md)
            }
        }
        .padding(.bottom, DS.Spacing.sm)
    }
}


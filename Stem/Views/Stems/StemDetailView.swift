import SwiftUI

struct StemDetailView: View {
    let stemId: String
    @State private var vm: StemDetailViewModel
    @State private var showAddFind = false
    @State private var showEditStem = false
    @State private var safariURL: URL?

    init(stemId: String) {
        self.stemId = stemId
        self._vm = State(initialValue: StemDetailViewModel(stemId: stemId))
    }

    var body: some View {
        ScrollView {
            if vm.loading && vm.stem == nil {
                LoadingView()
                    .padding(.top, 60)
            } else if let stem = vm.stem {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    headerView(stem)

                    // Finds
                    if vm.finds.isEmpty {
                        EmptyStateView(
                            icon: "🔍",
                            title: "No finds yet",
                            message: vm.isOwner ? "Add your first find to get started" : nil
                        )
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.finds) { find in
                                FindCard(find: find) {
                                    if let url = URL(string: find.url) {
                                        safariURL = url
                                    }
                                }
                                if find.id != vm.finds.last?.id {
                                    Divider()
                                        .padding(.horizontal, DS.Spacing.md)
                                }
                            }
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
            ToolbarItem(placement: .primaryAction) {
                Button { showAddFind = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.forest)
                }
            }
            if let stem = vm.stem {
                ToolbarItem(placement: .secondaryAction) {
                    if let username = stem.username {
                        ShareLink(item: URL(string: "https://stem.md/\(username)/\(stem.slug)")!) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                if vm.isOwner {
                    ToolbarItem(placement: .secondaryAction) {
                        Button { showEditStem = true } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFind) {
            AddFindSheet(stemId: stemId) { success in
                if success {
                    Task { await vm.load() }
                }
            }
        }
        .sheet(isPresented: $showEditStem) {
            if let stem = vm.stem {
                EditStemView(stem: stem, existingCategories: vm.categories) {
                    Task { await vm.load() }
                }
            }
        }
        .fullScreenCover(item: $safariURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .stemNavigationDestinations()
        .refreshable {
            await vm.load()
            Haptic.play(.refresh)
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func headerView(_ stem: Stem) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            if let emoji = stem.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 40))
            }

            Text(stem.title)
                .font(.heading(DS.FontSize.title))
                .foregroundStyle(Color.ink)

            if let username = stem.username {
                NavigationLink(value: StemNavigation.profile(username)) {
                    Text("@\(username)")
                        .font(.mono(DS.FontSize.small))
                        .foregroundStyle(Color.forest)
                }
            }

            if let desc = stem.description, !desc.isEmpty {
                Text(desc)
                    .font(.body(DS.FontSize.body))
                    .foregroundStyle(Color.inkMid)
            }

            HStack(spacing: DS.Spacing.md) {
                NavigationLink(value: StemNavigation.stemFollowers(stemId)) {
                    Text("\(vm.followerCount) followers")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.forest)
                }

                Text("\(vm.finds.count) finds")
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkLight)

                if stem.isBranch {
                    Text("Branch")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.forest)
                }
            }

            if !vm.isOwner {
                FollowButton(isFollowing: vm.isFollowing) {
                    Task { await vm.toggleFollow() }
                }
            }
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.categoryTint(stem.primaryCategory ?? ""))
    }
}

import SwiftUI

struct ExploreView: View {
    @State private var vm = ExploreViewModel()
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                if vm.isSearchActive {
                    searchResultsView
                } else if vm.loading && vm.trending.isEmpty {
                    LoadingView()
                        .padding(.top, 60)
                } else {
                    defaultExploreView
                }
            }
            .background(Color.paper)
            .navigationTitle("Explore")
            .searchable(text: $vm.searchQuery, prompt: "Search stems and people")
            .onChange(of: vm.searchQuery) { vm.search() }
            .stemNavigationDestinations()
            .refreshable { await vm.load() }
        }
        .task { await vm.load() }
    }

    // MARK: - Default Explore

    private var defaultExploreView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            // Trending stems
            if !vm.trending.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Trending")
                        .font(.heading(DS.FontSize.headingLarge))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, DS.Spacing.md)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Spacing.sm) {
                            ForEach(vm.trending) { stem in
                                Button {
                                    navPath.append(StemNavigation.stemDetail(stem.id))
                                } label: {
                                    StemCard(stem: stem)
                                        .frame(width: 240, height: 180, alignment: .topLeading)
                                        .clipped()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, DS.Spacing.md)
                    }
                }
            }

            // Categories
            if !vm.categories.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Categories")
                        .font(.heading(DS.FontSize.headingLarge))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, DS.Spacing.md)

                    FlowLayout(spacing: 8) {
                        ForEach(vm.categories) { cat in
                            if let category = categoryById(cat.id) {
                                Button {
                                    navPath.append(StemNavigation.category(cat.id))
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(category.emoji)
                                            .font(.system(size: 13))
                                        Text(category.name)
                                            .font(.body(DS.FontSize.small))
                                        Text("\(cat.stemCount)")
                                            .font(.mono(DS.FontSize.tiny))
                                            .foregroundStyle(Color.inkLight)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.categoryTint(cat.id))
                                    .foregroundStyle(Color.ink)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(Color.paperDark, lineWidth: 1))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                }
            }

            // Top people
            if !vm.topUsers.isEmpty {
                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("People")
                        .font(.heading(DS.FontSize.headingLarge))
                        .foregroundStyle(Color.ink)
                        .padding(.horizontal, DS.Spacing.md)

                    ForEach(vm.topUsers) { user in
                        UserCard(user: user, onTap: {
                            navPath.append(StemNavigation.profile(user.username))
                        })
                        .padding(.horizontal, DS.Spacing.md)
                    }
                }
            }

            Spacer().frame(height: DS.Spacing.xl)
        }
        .padding(.top, DS.Spacing.sm)
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            if vm.searching {
                LoadingView()
                    .padding(.top, 40)
            } else if let results = vm.searchResults {
                if results.stems.isEmpty && results.users.isEmpty {
                    EmptyStateView(
                        icon: "🔍",
                        title: "No results",
                        message: "Try a different search"
                    )
                } else {
                    if !results.stems.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("Stems")
                                .font(.heading(DS.FontSize.heading))
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, DS.Spacing.md)

                            ForEach(results.stems) { stem in
                                Button {
                                    navPath.append(StemNavigation.stemDetail(stem.id))
                                } label: {
                                    StemCard(stem: stem)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, DS.Spacing.md)
                            }
                        }
                    }

                    if !results.users.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("People")
                                .font(.heading(DS.FontSize.heading))
                                .foregroundStyle(Color.ink)
                                .padding(.horizontal, DS.Spacing.md)

                            ForEach(results.users) { user in
                                UserCard(user: user, onTap: {
                                    navPath.append(StemNavigation.profile(user.username))
                                })
                                .padding(.horizontal, DS.Spacing.md)
                            }
                        }
                    }
                }
            }

            Spacer().frame(height: DS.Spacing.xl)
        }
        .padding(.top, DS.Spacing.sm)
    }
}

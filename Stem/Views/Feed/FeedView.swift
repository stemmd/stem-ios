import SwiftUI
import SafariServices

struct FeedView: View {
    @Binding var showCreateStem: Bool
    @State private var vm = FeedViewModel()
    @State private var safariURL: URL?
    @State private var navPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                if vm.loading && vm.groupedFeed.isEmpty {
                    LoadingView()
                        .padding(.top, 60)
                } else if vm.groupedFeed.isEmpty {
                    EmptyStateView(
                        icon: "🌱",
                        title: "Your feed is quiet",
                        message: "Follow some stems or people to see artifacts here"
                    )
                } else {
                    LazyVStack(spacing: DS.Spacing.md) {
                        ForEach(vm.groupedFeed) { group in
                            Text(group.period)
                                .font(.heading(DS.FontSize.heading))
                                .foregroundStyle(Color.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, DS.Spacing.md)
                                .padding(.top, DS.Spacing.lg)
                                .padding(.bottom, DS.Spacing.sm)

                            ForEach(group.stemGroups) { stemGroup in
                                FeedGroupCard(
                                    stemTitle: stemGroup.stemTitle,
                                    stemEmoji: stemGroup.stemEmoji,
                                    stemSlug: stemGroup.stemSlug,
                                    stemUsername: stemGroup.stemUsername,
                                    stemCategory: stemGroup.stemCategory,
                                    artifacts: stemGroup.artifacts,
                                    onStemTap: {
                                        navPath.append(StemNavigation.stemDetail(stemGroup.stemId))
                                    },
                                    onArtifactTap: { artifact in
                                        if !artifact.isNote, let url = URL(string: artifact.url) {
                                            safariURL = url
                                            Analytics.track("open_link")
                                        } else {
                                            navPath.append(StemNavigation.stemDetail(stemGroup.stemId))
                                        }
                                    },
                                    onAuthorTap: {
                                        navPath.append(StemNavigation.profile(stemGroup.stemUsername))
                                    }
                                )
                                .fadeIn()
                            }
                        }

                        if vm.hasMore {
                            ProgressView()
                                .tint(Color.forest)
                                .onAppear {
                                    Task { await vm.loadMore() }
                                }
                                .padding()
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                }
            }
            .background(Color.paper)
            .navigationTitle("Feed")
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Haptic.play(.toggle)
                    showCreateStem = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.forest)
                        .clipShape(Circle())
                        .shadow(color: Color.forest.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.trailing, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.lg)
            }
            .refreshable {
                await vm.load()
                Haptic.play(.refresh)
            }
            .stemNavigationDestinations()
            .fullScreenCover(item: $safariURL) { url in
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
        .task { await vm.load() }
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.preferredControlTintColor = UIColor(hex: "2D5A3D")
        return vc
    }

    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

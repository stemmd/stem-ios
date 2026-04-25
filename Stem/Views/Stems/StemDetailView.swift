import SwiftUI

/// Where focus is currently pointing.
/// The entire stem stays on screen behind; a focused target "pulls closer" via a zooming card.
enum FocusTarget: Hashable {
    case artifact(String)
    case node(String)

    var matchedID: String {
        switch self {
        case .artifact(let id): return "artifact-\(id)"
        case .node(let id): return "node-\(id)"
        }
    }
}

struct StemDetailView: View {
    let stemId: String
    @State private var vm: StemDetailViewModel
    @State private var focused: FocusTarget?
    @State private var showAddArtifact = false
    @State private var showEditStem = false
    @State private var safariURL: URL?
    @Namespace private var focusNamespace

    init(stemId: String) {
        self.stemId = stemId
        self._vm = State(initialValue: StemDetailViewModel(stemId: stemId))
    }

    var body: some View {
        ZStack {
            // Plant: always visible, fades and softens when something is in focus.
            scrollContent
                .blur(radius: focused == nil ? 0 : 10)
                .scaleEffect(focused == nil ? 1.0 : 0.98)
                .animation(.spring(response: 0.4, dampingFraction: 0.88), value: focused)
                .allowsHitTesting(focused == nil)

            // Dim backdrop
            if focused != nil {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { dismissFocus() }
                    .transition(.opacity)
            }

            // Focused leaf pulled forward
            if let target = focused {
                StemFocusLayer(
                    target: target,
                    vm: vm,
                    namespace: focusNamespace,
                    onDismiss: { dismissFocus() },
                    onOpenURL: { url in safariURL = url },
                    onTransferFocus: { newTarget in
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            focused = newTarget
                        }
                        Haptic.play(.toggle)
                    }
                )
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.xl)
                .padding(.bottom, DS.Spacing.xl)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.92).combined(with: .opacity)
                ))
            }
        }
        .background(Color.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddArtifact = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color.forest)
                }
                .disabled(focused != nil)
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
        .sheet(isPresented: $showAddArtifact) {
            AddArtifactSheet(stemId: stemId) { success in
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

    private func dismissFocus() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
            focused = nil
        }
        Haptic.play(.toggle)
    }

    @ViewBuilder
    private var scrollContent: some View {
        ScrollView {
            if vm.loading && vm.stem == nil {
                LoadingView()
                    .padding(.top, 60)
            } else if let stem = vm.stem {
                VStack(alignment: .leading, spacing: 0) {
                    StemHeaderView(stem: stem, vm: vm)

                    StemOverviewView(
                        vm: vm,
                        focused: $focused,
                        namespace: focusNamespace,
                        onOpenAddArtifact: { showAddArtifact = true }
                    )
                    .padding(.top, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.xl)
                }
            } else if let error = vm.error {
                EmptyStateView(icon: "⚠️", title: "Something went wrong", message: error)
            }
        }
    }
}

// MARK: - Header

private struct StemHeaderView: View {
    let stem: Stem
    @Bindable var vm: StemDetailViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            if let emoji = stem.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 44))
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
                NavigationLink(value: StemNavigation.stemFollowers(stem.id)) {
                    Text(vm.followerCount == 1 ? "1 follower" : "\(vm.followerCount) followers")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(Color.forest)
                }

                Text(vm.artifacts.count == 1 ? "1 artifact" : "\(vm.artifacts.count) artifacts")
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

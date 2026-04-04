import SwiftUI

struct CategoryDetailView: View {
    let categoryId: String
    @State private var stems: [Stem] = []
    @State private var loading = true
    @State private var offset = 0

    private var category: StemCategory? { categoryById(categoryId) }

    var body: some View {
        ScrollView {
            if loading && stems.isEmpty {
                LoadingView()
                    .padding(.top, 60)
            } else if stems.isEmpty {
                EmptyStateView(
                    icon: category?.emoji ?? "📂",
                    title: "No stems yet",
                    message: "Be the first to create a stem in this category"
                )
            } else {
                LazyVStack(spacing: DS.Spacing.sm) {
                    ForEach(stems) { stem in
                        NavigationLink(value: StemNavigation.stemDetail(stem.id)) {
                            StemCard(stem: stem)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.top, DS.Spacing.sm)
            }
        }
        .background(Color.paper)
        .navigationTitle(category.map { "\($0.emoji) \($0.name)" } ?? "Category")
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.getExploreCategory(categoryId: categoryId)
            stems = res.stems
        } catch {}
        loading = false
    }
}

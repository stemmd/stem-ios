import Foundation

@MainActor @Observable
final class ExploreViewModel {
    var trending: [Stem] = []
    var categories: [CategoryCount] = []
    var topUsers: [User] = []
    var loading = true
    var error: String?

    // Search
    var searchQuery = ""
    var searchResults: SearchResponse?
    var searching = false
    var isSearchActive: Bool { !searchQuery.isEmpty }

    private var searchTask: Task<Void, Never>?

    func load() async {
        loading = true
        error = nil
        do {
            let res = try await APIClient.shared.getExplore()
            trending = res.trending
            categories = res.categories
            topUsers = res.topUsers
        } catch {
            self.error = "Couldn't load explore"
        }
        loading = false
    }

    func search() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            searchResults = nil
            searching = false
            return
        }

        searchTask?.cancel()
        searchTask = Task {
            // Debounce 300ms
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            searching = true
            Analytics.track("search", ["query_length": String(query.count)])
            do {
                let res = try await APIClient.shared.search(query: query)
                guard !Task.isCancelled else { return }
                searchResults = res
            } catch {}
            searching = false
        }
    }
}

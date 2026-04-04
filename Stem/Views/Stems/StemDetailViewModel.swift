import Foundation

@MainActor @Observable
final class StemDetailViewModel {
    var stem: Stem?
    var finds: [Find] = []
    var followerCount = 0
    var isFollowing = false
    var isOwner = false
    var categories: [String] = []
    var loading = true
    var error: String?

    private let stemId: String

    init(stemId: String) {
        self.stemId = stemId
    }

    func load() async {
        loading = true
        error = nil
        do {
            let res = try await APIClient.shared.getStemDetail(id: stemId)
            stem = res.stem
            finds = res.finds
            followerCount = res.followerCount
            isFollowing = res.isFollowing
            isOwner = res.isOwner
            categories = res.categories ?? []
        } catch {
            self.error = "Couldn't load this stem"
        }
        loading = false
    }

    private var isTogglingFollow = false

    func toggleFollow() async {
        guard !isTogglingFollow else { return }
        isTogglingFollow = true
        defer { isTogglingFollow = false }
        let wasFollowing = isFollowing
        isFollowing.toggle()
        followerCount += isFollowing ? 1 : -1
        do {
            if isFollowing {
                _ = try await APIClient.shared.followStem(id: stemId)
            } else {
                _ = try await APIClient.shared.unfollowStem(id: stemId)
            }
        } catch {
            // Revert on failure
            isFollowing = wasFollowing
            followerCount += wasFollowing ? 1 : -1
        }
    }

}

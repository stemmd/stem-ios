import Foundation

@MainActor @Observable
final class ProfileViewModel {
    var user: User?
    var stems: [Stem] = []
    var followerCount = 0
    var followingCount = 0
    var isFollowing = false
    var isOwner = false
    var loading = true
    var error: String?

    private let username: String

    init(username: String) {
        self.username = username
    }

    func load() async {
        loading = true
        error = nil
        do {
            let res = try await APIClient.shared.getUserProfile(username: username)
            user = res.user
            stems = res.stems
            followerCount = res.followerCount
            followingCount = res.followingCount
            isFollowing = res.isFollowing
            isOwner = res.isOwner
        } catch {
            self.error = "Couldn't load this profile"
        }
        loading = false
    }

    private var isTogglingFollow = false

    func toggleFollow() async {
        guard let userId = user?.id, !isTogglingFollow else { return }
        isTogglingFollow = true
        defer { isTogglingFollow = false }
        let wasFollowing = isFollowing
        isFollowing.toggle()
        followerCount += isFollowing ? 1 : -1
        Haptic.play(.follow)
        Analytics.track(isFollowing ? "follow_user" : "unfollow_user")
        do {
            if isFollowing {
                _ = try await APIClient.shared.followUser(id: userId)
            } else {
                _ = try await APIClient.shared.unfollowUser(id: userId)
            }
        } catch {
            isFollowing = wasFollowing
            followerCount += wasFollowing ? 1 : -1
        }
    }

    /// Group stems by their primary category
    var stemsByCategory: [(category: String, stems: [Stem])] {
        var groups: [String: [Stem]] = [:]
        var order: [String] = []
        for stem in stems {
            let cat = stem.primaryCategory ?? "uncategorized"
            if groups[cat] == nil { order.append(cat) }
            groups[cat, default: []].append(stem)
        }
        return order.compactMap { cat in
            guard let stems = groups[cat] else { return nil }
            return (category: cat, stems: stems)
        }
    }
}

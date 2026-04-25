import Foundation

@MainActor @Observable
final class FeedViewModel {
    var groupedFeed: [TimePeriodGroup] = []
    var hasMore = false
    var loading = true
    var error: String?

    private var artifacts: [Artifact] = []

    func load() async {
        loading = true
        error = nil
        do {
            let res = try await APIClient.shared.getFeed()
            artifacts = res.artifacts
            hasMore = res.hasMore
            regroup()
        } catch {
            self.error = "Couldn't load your feed"
        }
        loading = false
    }

    func loadMore() async {
        guard let last = artifacts.last?.createdAt else { return }
        do {
            let res = try await APIClient.shared.getFeed(before: last)
            artifacts.append(contentsOf: res.artifacts)
            hasMore = res.hasMore
            regroup()
        } catch {
            hasMore = false
        }
    }

    private func regroup() {
        groupedFeed = Self.groupByTimePeriod(artifacts)
    }

    // MARK: - Grouping

    static func groupByTimePeriod(_ artifacts: [Artifact]) -> [TimePeriodGroup] {
        var groups: [(String, [Artifact])] = []
        var currentPeriod = ""
        var currentArtifacts: [Artifact] = []

        for artifact in artifacts {
            let period = RelativeDate.timePeriod(for: artifact.createdAt ?? "")
            if period != currentPeriod {
                if !currentArtifacts.isEmpty {
                    groups.append((currentPeriod, currentArtifacts))
                }
                currentPeriod = period
                currentArtifacts = [artifact]
            } else {
                currentArtifacts.append(artifact)
            }
        }
        if !currentArtifacts.isEmpty {
            groups.append((currentPeriod, currentArtifacts))
        }
        return groups.map { TimePeriodGroup(period: $0.0, stemGroups: groupByStem($0.1, period: $0.0)) }
    }

    private static func groupByStem(_ artifacts: [Artifact], period: String) -> [StemFeedGroup] {
        var groups: [String: [Artifact]] = [:]
        var order: [String] = []

        for artifact in artifacts {
            let key = artifact.stemId ?? artifact.stemSlug ?? artifact.id
            if groups[key] == nil {
                order.append(key)
                groups[key] = []
            }
            groups[key]?.append(artifact)
        }

        return order.compactMap { key in
            guard let artifacts = groups[key], let first = artifacts.first else { return nil }
            return StemFeedGroup(
                stemId: first.stemId ?? key,
                stemTitle: first.stemTitle ?? "",
                stemEmoji: first.stemEmoji,
                stemSlug: first.stemSlug ?? "",
                stemUsername: first.stemUsername ?? "",
                stemCategory: first.stemCategory,
                artifacts: artifacts,
                period: period
            )
        }
    }
}

struct TimePeriodGroup: Identifiable {
    let period: String
    let stemGroups: [StemFeedGroup]
    var id: String { period }
}

struct StemFeedGroup: Identifiable {
    let stemId: String
    let stemTitle: String
    let stemEmoji: String?
    let stemSlug: String
    let stemUsername: String
    let stemCategory: String?
    let artifacts: [Artifact]
    let period: String
    var id: String { "\(period):\(stemId)" }
}

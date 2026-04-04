import Foundation

@MainActor @Observable
final class FeedViewModel {
    var groupedFeed: [TimePeriodGroup] = []
    var hasMore = false
    var loading = true
    var error: String?

    private var finds: [Find] = []

    func load() async {
        loading = true
        error = nil
        do {
            let res = try await APIClient.shared.getFeed()
            finds = res.finds
            hasMore = res.hasMore
            regroup()
        } catch {
            self.error = "Couldn't load your feed"
        }
        loading = false
    }

    func loadMore() async {
        guard let last = finds.last?.createdAt else { return }
        do {
            let res = try await APIClient.shared.getFeed(before: last)
            finds.append(contentsOf: res.finds)
            hasMore = res.hasMore
            regroup()
        } catch {
            hasMore = false
        }
    }

    private func regroup() {
        groupedFeed = Self.groupByTimePeriod(finds)
    }

    // MARK: - Grouping

    static func groupByTimePeriod(_ finds: [Find]) -> [TimePeriodGroup] {
        var groups: [(String, [Find])] = []
        var currentPeriod = ""
        var currentFinds: [Find] = []

        for find in finds {
            let period = RelativeDate.timePeriod(for: find.createdAt ?? "")
            if period != currentPeriod {
                if !currentFinds.isEmpty {
                    groups.append((currentPeriod, currentFinds))
                }
                currentPeriod = period
                currentFinds = [find]
            } else {
                currentFinds.append(find)
            }
        }
        if !currentFinds.isEmpty {
            groups.append((currentPeriod, currentFinds))
        }
        return groups.map { TimePeriodGroup(period: $0.0, stemGroups: groupByStem($0.1, period: $0.0)) }
    }

    private static func groupByStem(_ finds: [Find], period: String) -> [StemFeedGroup] {
        var groups: [String: [Find]] = [:]
        var order: [String] = []

        for find in finds {
            let key = find.stemId ?? find.stemSlug ?? find.id
            if groups[key] == nil {
                order.append(key)
                groups[key] = []
            }
            groups[key]?.append(find)
        }

        return order.compactMap { key in
            guard let finds = groups[key], let first = finds.first else { return nil }
            return StemFeedGroup(
                stemId: first.stemId ?? key,
                stemTitle: first.stemTitle ?? "",
                stemEmoji: first.stemEmoji,
                stemSlug: first.stemSlug ?? "",
                stemUsername: first.stemUsername ?? "",
                stemCategory: first.stemCategory,
                finds: finds,
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
    let finds: [Find]
    let period: String
    var id: String { "\(period):\(stemId)" }
}

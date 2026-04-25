import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [StemNotification] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if loading && notifications.isEmpty {
                    LoadingView()
                        .padding(.top, 60)
                } else if notifications.isEmpty {
                    EmptyStateView(
                        icon: "🔔",
                        title: "No notifications yet",
                        message: "Follow some stems and people to get started"
                    )
                } else {
                    LazyVStack(spacing: 2) {
                        ForEach(notifications) { n in
                            NavigationLink(value: notificationDestination(n)) {
                                NotificationRow(notification: n)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.sm)
                }
            }
            .background(Color.paper)
            .navigationTitle("Notifications")
            .stemNavigationDestinations()
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.getNotifications()
            notifications = res.notifications
            if res.unreadCount > 0 {
                _ = try? await APIClient.shared.markNotificationsRead()
            }
        } catch {}
        loading = false
    }

    private func notificationDestination(_ n: StemNotification) -> StemNavigation {
        switch n.type {
        case .newFollower:
            return .profile(n.actorUsername)
        case .stemFollowed, .newArtifact, .artifactApproved:
            if let stemId = n.stemId {
                return .stemDetail(stemId)
            }
            return .profile(n.actorUsername)
        }
    }
}

struct NotificationRow: View {
    let notification: StemNotification

    private var text: String {
        let actor = notification.actorDisplayName ?? "@\(notification.actorUsername)"
        let stem = notification.stemTitle ?? "your stem"
        switch notification.type {
        case .newFollower:
            return "\(actor) followed you"
        case .stemFollowed:
            return "\(actor) followed \(stem)"
        case .newArtifact:
            return "\(actor) added to \(stem)"
        case .artifactApproved:
            return "\(stem) accepted your addition"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(
                url: notification.actorAvatarUrl,
                name: notification.actorDisplayName ?? notification.actorUsername,
                size: 36
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.body(DS.FontSize.body))
                    .foregroundStyle(Color.ink)
                Text(RelativeDate.format(notification.createdAt))
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkLight)
            }

            Spacer()

            if notification.isUnread {
                Circle()
                    .fill(Color.forest)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(14)
        .background(notification.isUnread ? Color.leaf : .clear)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
    }
}

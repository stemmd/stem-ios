import SwiftUI

struct NotificationsView: View {
    @State private var notifications: [StemNotification] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if loading && notifications.isEmpty {
                    ProgressView().padding(.top, 60)
                } else if notifications.isEmpty {
                    Text("Nothing here yet. Go explore some stems.")
                        .font(.custom("DMSans-Regular", size: 15))
                        .foregroundStyle(Color("InkLight"))
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 2) {
                        ForEach(notifications) { n in
                            NotificationRow(notification: n)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Notifications")
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.getNotifications()
            notifications = res.notifications
            try? await APIClient.shared.markNotificationsRead()
        } catch {}
        loading = false
    }
}

struct NotificationRow: View {
    let notification: StemNotification

    private var text: String {
        let actor = notification.actorDisplayName ?? "@\(notification.actorUsername)"
        switch notification.type {
        case "new_follower": return "\(actor) followed you"
        case "stem_followed": return "\(actor) followed \(notification.stemTitle ?? "your stem")"
        case "new_find": return "\(actor) added a find to \(notification.stemTitle ?? "your stem")"
        case "find_approved": return "Your find was approved in \(notification.stemTitle ?? "a stem")"
        default: return "New notification"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color("PaperDark"))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(notification.actorUsername.prefix(1)).uppercased())
                        .font(.custom("DMMono-Regular", size: 13))
                        .foregroundStyle(Color("InkMid"))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.custom("DMSans-Regular", size: 14))
                    .foregroundStyle(Color("Ink"))
                Text(notification.createdAt)
                    .font(.custom("DMMono-Regular", size: 11))
                    .foregroundStyle(Color("InkLight"))
            }

            Spacer()

            if notification.read == 0 {
                Circle()
                    .fill(Color("Forest"))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(14)
        .background(notification.read == 0 ? Color("Leaf") : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

import SwiftUI

struct ContentView: View {
    let currentUser: User?
    @State private var selectedTab = 0
    @State private var notificationCount = 0
    @State private var showCreateStem = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
        }
        .tint(Color.forest)
        .sheet(isPresented: $showCreateStem) {
            CreateStemView(onCreated: { showCreateStem = false })
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await pollNotifications()
        }
    }

    // iOS 18+ — Tab API with Liquid Glass support
    @available(iOS 18.0, *)
    private var modernTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Feed", systemImage: "leaf", value: 0) {
                FeedView(showCreateStem: $showCreateStem)
            }
            Tab("Explore", systemImage: "magnifyingglass", value: 1) {
                ExploreView()
            }
            Tab("Notifications", systemImage: "bell", value: 2) {
                NotificationsView()
            }
            .badge(notificationCount)
            Tab("Profile", systemImage: "person.circle", value: 3) {
                profileTab
            }
        }
        .tabViewStyle(.tabBarOnly)
        .modifier(TabBarMinimizeModifier())
    }

    // iOS 17 fallback
    private var legacyTabView: some View {
        TabView(selection: $selectedTab) {
            FeedView(showCreateStem: $showCreateStem)
                .tabItem { Label("Feed", systemImage: "leaf") }
                .tag(0)
            ExploreView()
                .tabItem { Label("Explore", systemImage: "magnifyingglass") }
                .tag(1)
            NotificationsView()
                .tabItem { Label("Notifications", systemImage: "bell") }
                .badge(notificationCount)
                .tag(2)
            profileTab
                .tabItem { Label("Profile", systemImage: "person.circle") }
                .tag(3)
        }
    }

    @ViewBuilder
    private var profileTab: some View {
        NavigationStack {
            if let user = currentUser {
                ProfileView(username: user.username)
            } else {
                SettingsView()
            }
        }
    }

    private func pollNotifications() async {
        while !Task.isCancelled {
            do {
                let res = try await APIClient.shared.getNotificationCount()
                notificationCount = res.count
            } catch {}
            try? await Task.sleep(for: .seconds(60))
        }
    }
}

struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

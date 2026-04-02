import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Image(systemName: "leaf")
                    Text("Feed")
                }
                .tag(0)

            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .tag(1)

            CreateStemView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("New")
                }
                .tag(2)

            NotificationsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .tint(Color("Forest"))
    }
}

import SwiftUI

enum StemNavigation: Hashable {
    case stemDetail(String)
    case profile(String)
    case category(String)
    case followers(String)
    case stemFollowers(String)
}

extension View {
    func stemNavigationDestinations() -> some View {
        self.navigationDestination(for: StemNavigation.self) { nav in
            switch nav {
            case .stemDetail(let id):
                StemDetailView(stemId: id)
            case .profile(let username):
                ProfileView(username: username)
            case .category(let id):
                CategoryDetailView(categoryId: id)
            case .followers(let username):
                FollowerListView(username: username)
            case .stemFollowers(let stemId):
                StemFollowerListView(stemId: stemId, stemTitle: "")
            }
        }
    }
}

import SwiftUI

@main
struct StemApp: App {
    @State private var api = APIClient.shared

    var body: some Scene {
        WindowGroup {
            if api.isAuthenticated {
                ContentView()
            } else {
                AuthView()
            }
        }
    }
}

import SwiftUI

@main
struct StemApp: App {
    @State private var api = APIClient.shared
    @State private var currentUser: User?
    @State private var checkingUser = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearance") private var appearance = "system"
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if !api.isAuthenticated {
                    AuthView()
                } else if checkingUser {
                    // Brief loading while we check if user is new or returning
                    LoadingView()
                        .background(Color.paper)
                } else if !hasCompletedOnboarding {
                    OnboardingContainerView()
                } else {
                    ContentView(currentUser: currentUser)
                }
            }
            .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
            .onChange(of: api.isAuthenticated) {
                if api.isAuthenticated {
                    Task { await checkUserStatus() }
                }
            }
            .task {
                Analytics.track("app_open")
                if api.isAuthenticated {
                    await checkUserStatus()
                }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .background {
                    Analytics.shared.flush()
                }
            }
        }
    }

    private func checkUserStatus() async {
        checkingUser = true
        do {
            let res = try await APIClient.shared.getCurrentUser()
            currentUser = res.user

            // If user already has stems, they're a returning user — skip onboarding
            if !hasCompletedOnboarding {
                let stemsRes = try await APIClient.shared.getMyStems()
                if !stemsRes.stems.isEmpty {
                    hasCompletedOnboarding = true
                }
            }
        } catch {}
        checkingUser = false
    }
}

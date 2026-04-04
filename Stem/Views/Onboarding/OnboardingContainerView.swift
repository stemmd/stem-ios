import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var selectedInterests: Set<String> = []

    private let pageCount = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingWelcomeView { advance() }
                    .tag(0)
                OnboardingStemView { advance() }
                    .tag(1)
                OnboardingFindView { advance() }
                    .tag(2)
                OnboardingCategoriesView(
                    selectedInterests: $selectedInterests,
                    onDone: { completeOnboarding() }
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(DS.Animation.smooth, value: currentPage)

            // Page dots
            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { i in
                    Circle()
                        .fill(i == currentPage ? Color.forest : Color.paperDark)
                        .frame(width: 8, height: 8)
                        .animation(DS.Animation.quick, value: currentPage)
                }
            }
            .padding(.bottom, DS.Spacing.xl)
        }
        .background(Color.paper)
    }

    private func advance() {
        Haptic.play(.toggle)
        if currentPage < pageCount - 1 {
            currentPage += 1
        }
    }

    private func completeOnboarding() {
        // Save interests to API
        Task {
            if !selectedInterests.isEmpty {
                // POST interests (will be implemented when API supports it)
            }
            Haptic.play(.saved)
            Analytics.track("onboarding_complete", ["interests": String(selectedInterests.count)])
            hasCompletedOnboarding = true
        }
    }
}

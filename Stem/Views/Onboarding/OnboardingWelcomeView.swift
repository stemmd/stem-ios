import SwiftUI

struct OnboardingWelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            // Stem logo
            Image("StemLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

            VStack(spacing: DS.Spacing.sm) {
                Text("Find trails worth following")
                    .font(.heading(DS.FontSize.hero))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)

                Text("Leave trails worth finding")
                    .font(.heading(DS.FontSize.hero))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            StemButton(title: "Get started", fullWidth: true) {
                onNext()
            }

            Spacer().frame(height: DS.Spacing.xl)
        }
        .padding(.horizontal, DS.Spacing.xl)
    }
}

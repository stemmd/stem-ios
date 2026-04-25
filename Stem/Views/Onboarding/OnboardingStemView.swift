import SwiftUI

struct OnboardingStemView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            // Mini stem card mockup
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("🏗️")
                    .font(.system(size: 28))
                Text("Japanese Architecture")
                    .font(.heading(DS.FontSize.headingLarge))
                    .foregroundStyle(Color.ink)
                Text("Temples, minimalism, wabi-sabi")
                    .font(.body(DS.FontSize.small))
                    .foregroundStyle(Color.inkMid)
                Text("12 artifacts")
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkLight)
            }
            .padding(DS.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.categoryTint("cat_architecture"))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .strokeBorder(Color.paperDark, lineWidth: 1)
            )
            .padding(.horizontal, DS.Spacing.xl)

            VStack(spacing: DS.Spacing.sm) {
                Text("This is a stem")
                    .font(.heading(DS.FontSize.title))
                    .foregroundStyle(Color.ink)

                Text("Pick a topic, start collecting, and follow the trail")
                    .font(.body(DS.FontSize.bodyLarge))
                    .foregroundStyle(Color.inkMid)
                    .multilineTextAlignment(.center)

                Text("Invite others to contribute and it becomes a branch")
                    .font(.body(DS.FontSize.small))
                    .foregroundStyle(Color.inkLight)
                    .multilineTextAlignment(.center)
                    .padding(.top, DS.Spacing.xs)
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            StemButton(title: "Next", fullWidth: true) { onNext() }
                .padding(.horizontal, DS.Spacing.xl)

            Spacer().frame(height: DS.Spacing.xl)
        }
    }
}

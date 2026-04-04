import SwiftUI

struct OnboardingFindView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            // Mini find card mockup
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.paperMid)
                        .frame(width: 14, height: 14)
                    Text("The Hidden Geometry of Kyoto Gardens")
                        .font(.body(DS.FontSize.bodyLarge, weight: .medium))
                        .foregroundStyle(Color.ink)
                        .lineLimit(2)
                }

                Text("archDaily.com")
                    .font(.mono(DS.FontSize.caption))
                    .foregroundStyle(Color.inkLight)

                Text("How ancient mathematical principles shape the seemingly random beauty of Japanese landscape design")
                    .font(.body(DS.FontSize.small))
                    .foregroundStyle(Color.inkMid)
                    .italic()
                    .lineLimit(3)
            }
            .padding(DS.Spacing.md)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.medium)
                    .strokeBorder(Color.paperDark, lineWidth: 1)
            )
            .padding(.horizontal, DS.Spacing.xl)

            VStack(spacing: DS.Spacing.sm) {
                Text("This is a find")
                    .font(.heading(DS.FontSize.title))
                    .foregroundStyle(Color.ink)

                Text("Articles, videos, tweets, papers, any link you discover along a trail")
                    .font(.body(DS.FontSize.bodyLarge))
                    .foregroundStyle(Color.inkMid)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.xl)

            Spacer()

            StemButton(title: "Next", fullWidth: true) { onNext() }
                .padding(.horizontal, DS.Spacing.xl)

            Spacer().frame(height: DS.Spacing.xl)
        }
    }
}

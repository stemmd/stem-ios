import SwiftUI

struct OnboardingCategoriesView: View {
    @Binding var selectedInterests: Set<String>
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer().frame(height: DS.Spacing.xl)

            VStack(spacing: DS.Spacing.sm) {
                Text("What piques your curiosity?")
                    .font(.heading(DS.FontSize.title))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)

                Text("Pick a few to shape what shows up in your feed")
                    .font(.body(DS.FontSize.bodyLarge))
                    .foregroundStyle(Color.inkMid)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.xl)

            ScrollView {
                FlowLayout(spacing: 8) {
                    ForEach(allCategories) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedInterests.contains(category.id)
                        ) {
                            if selectedInterests.contains(category.id) {
                                selectedInterests.remove(category.id)
                            } else {
                                selectedInterests.insert(category.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }

            StemButton(
                title: "Done",
                fullWidth: true
            ) {
                onDone()
            }
            .disabled(selectedInterests.count < 3)
            .padding(.horizontal, DS.Spacing.xl)

            Text("\(selectedInterests.count) selected")
                .font(.mono(DS.FontSize.caption))
                .foregroundStyle(selectedInterests.count >= 3 ? Color.forest : Color.inkLight)

            Spacer().frame(height: DS.Spacing.md)
        }
    }
}

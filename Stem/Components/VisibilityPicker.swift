import SwiftUI

struct EnumRadioPicker<T: Hashable>: View {
    let label: String
    let options: [(value: T, title: String, subtitle: String)]
    @Binding var value: T

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(label)
                .font(.body(DS.FontSize.small, weight: .semibold))
                .foregroundStyle(Color.inkMid)

            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                HStack(spacing: DS.Spacing.sm) {
                    Image(systemName: value == option.value ? "circle.inset.filled" : "circle")
                        .foregroundStyle(value == option.value ? Color.forest : Color.inkLight)
                        .font(.system(size: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(option.title)
                            .font(.body(DS.FontSize.body, weight: .medium))
                            .foregroundStyle(Color.ink)
                        Text(option.subtitle)
                            .font(.body(DS.FontSize.small))
                            .foregroundStyle(Color.inkLight)
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    value = option.value
                    Haptic.play(.toggle)
                }
            }
        }
    }
}

struct VisibilityPicker: View {
    @Binding var value: Visibility
    var label = "Who can see this stem?"

    var body: some View {
        EnumRadioPicker(label: label, options: [
            (.public,  "Public",       "Shown in Explore, visible to anyone"),
            (.mutuals, "Mutuals only", "Visible to people you follow back"),
            (.private, "Just me",      "Fully private"),
        ], value: $value)
    }
}

struct ContributionPicker: View {
    @Binding var value: ContributionMode
    var label = "Who can suggest finds?"

    var body: some View {
        EnumRadioPicker(label: label, options: [
            (.open,    "Anyone",       "You approve each suggestion"),
            (.mutuals, "Mutuals only", "People you follow back"),
            (.closed,  "Just me",      "No suggestions accepted"),
        ], value: $value)
    }
}

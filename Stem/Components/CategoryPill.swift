import SwiftUI

struct CategoryPill: View {
    let category: StemCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(category.emoji)
                .font(.system(size: 13))
            Text(category.name)
                .font(.body(DS.FontSize.small))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isSelected ? Color.forest : Color.paperMid)
        .foregroundStyle(isSelected ? .white : Color.inkMid)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(isSelected ? Color.forest : Color.paperDark, lineWidth: 1)
        )
        .contentShape(Capsule())
        .onTapGesture {
            Haptic.play(.toggle)
            action()
        }
        .animation(DS.Animation.quick, value: isSelected)
    }
}

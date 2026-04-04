import SwiftUI

enum StemButtonStyle {
    case primary
    case secondary
    case destructive
}

struct StemButton: View {
    let title: String
    var style: StemButtonStyle = .primary
    var fullWidth: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                        .scaleEffect(0.8)
                }
                Text(title)
                    .font(.body(DS.FontSize.body, weight: .medium))
            }
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, DS.Spacing.md)
            .padding(.vertical, 16)
            .background(backgroundColor)
            .foregroundStyle(textColor)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .strokeBorder(borderColor, lineWidth: style == .secondary ? 1 : 0)
            )
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: .forest
        case .secondary: .clear
        case .destructive: .taken
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: .white
        case .secondary: .forest
        case .destructive: .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .secondary: .forest
        default: .clear
        }
    }
}

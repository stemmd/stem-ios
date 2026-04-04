import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            Text(icon)
                .font(.system(size: 48))

            Text(title)
                .font(.heading(DS.FontSize.heading))
                .foregroundStyle(Color.ink)
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.body(DS.FontSize.body))
                    .foregroundStyle(Color.inkMid)
                    .multilineTextAlignment(.center)
            }

            if let buttonTitle, let buttonAction {
                StemButton(title: buttonTitle, action: buttonAction)
                    .padding(.top, DS.Spacing.sm)
            }
        }
        .padding(DS.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

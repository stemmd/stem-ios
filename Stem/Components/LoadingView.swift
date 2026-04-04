import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .tint(Color.forest)
                .scaleEffect(1.1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

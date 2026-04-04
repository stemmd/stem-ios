import SwiftUI

// MARK: - Card Style

struct StemCardStyle: ViewModifier {
    var cornerRadius: CGFloat = DS.Radius.medium
    var tintColor: Color? = nil

    func body(content: Content) -> some View {
        content
            .background(tintColor ?? Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.paperDark, lineWidth: 1)
            )
    }
}

extension View {
    func stemCard(cornerRadius: CGFloat = DS.Radius.medium, tint: Color? = nil) -> some View {
        modifier(StemCardStyle(cornerRadius: cornerRadius, tintColor: tint))
    }
}

// MARK: - Fade-In Animation

struct FadeIn: ViewModifier {
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .onAppear {
                withAnimation(DS.Animation.smooth) {
                    appeared = true
                }
            }
    }
}

extension View {
    func fadeIn() -> some View {
        modifier(FadeIn())
    }
}

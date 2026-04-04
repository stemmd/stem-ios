import SwiftUI

struct StemTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .font(.body(DS.FontSize.body))
            .padding(12)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.small)
                    .strokeBorder(Color.paperDark, lineWidth: 1)
            )
    }
}

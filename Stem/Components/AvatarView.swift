import SwiftUI

struct AvatarView: View {
    let url: String?
    let name: String
    var size: CGFloat = 44

    var body: some View {
        if let url, !url.isEmpty, let imageURL = URL(string: url) {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    initialsView
                default:
                    initialsView
                        .opacity(0.6)
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(Color.paperMid)
                .frame(width: size, height: size)
            Text(initials)
                .font(.heading(size * 0.4))
                .foregroundStyle(Color.inkMid)
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

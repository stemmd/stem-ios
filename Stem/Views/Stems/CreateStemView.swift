import SwiftUI

struct CreateStemView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var emoji = ""
    @State private var visibility = "public"
    @State private var selectedCategories: Set<String> = []
    @State private var saving = false
    @State private var error: String?

    let categories = [
        ("cat_architecture", "Architecture", "🏗️"), ("cat_art", "Art", "🎨"),
        ("cat_biology", "Biology", "🌿"), ("cat_craft", "Craft", "🪡"),
        ("cat_design", "Design", "✏️"), ("cat_economics", "Economics", "📊"),
        ("cat_film", "Film", "🎬"), ("cat_food", "Food", "🍳"),
        ("cat_health", "Health", "🫀"), ("cat_history", "History", "🏛️"),
        ("cat_linguistics", "Linguistics", "🗣️"), ("cat_literature", "Literature", "📖"),
        ("cat_mathematics", "Mathematics", "∑"), ("cat_music", "Music", "🎵"),
        ("cat_nature", "Nature", "🌲"), ("cat_philosophy", "Philosophy", "🧠"),
        ("cat_photography", "Photography", "📷"), ("cat_physics", "Physics", "⚛️"),
        ("cat_politics", "Politics", "🌐"), ("cat_psychology", "Psychology", "🪞"),
        ("cat_science", "Science", "🔬"), ("cat_space", "Space", "🔭"),
        ("cat_sport", "Sport", "⚽"), ("cat_technology", "Technology", "💻"),
        ("cat_urbanism", "Urbanism", "🏙️"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What are you into?", text: $title)
                        .font(.custom("DMSans-Regular", size: 16))
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .font(.custom("DMSans-Regular", size: 14))
                        .lineLimit(3...6)
                }

                Section("Category") {
                    FlowLayout(spacing: 8) {
                        ForEach(categories, id: \.0) { cat in
                            Button {
                                if selectedCategories.contains(cat.0) {
                                    selectedCategories.remove(cat.0)
                                } else if selectedCategories.count < 3 {
                                    selectedCategories.insert(cat.0)
                                }
                            } label: {
                                Text("\(cat.2) \(cat.1)")
                                    .font(.custom("DMSans-Regular", size: 13))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategories.contains(cat.0) ? Color("Forest") : Color("PaperMid"))
                                    .foregroundStyle(selectedCategories.contains(cat.0) ? .white : Color("InkMid"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Section("Visibility") {
                    Picker("Who can see this?", selection: $visibility) {
                        Text("Public").tag("public")
                        Text("Mutuals").tag("mutuals")
                        Text("Just me").tag("private")
                    }
                    .pickerStyle(.segmented)
                }

                if let error {
                    Text(error)
                        .font(.custom("DMSans-Regular", size: 13))
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("New stem")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Creating..." : "Create") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).count < 2 || selectedCategories.isEmpty || saving)
                }
            }
        }
    }

    private func save() {
        saving = true
        error = nil
        Task {
            do {
                _ = try await APIClient.shared.createStem(CreateStemBody(
                    title: title.trimmingCharacters(in: .whitespaces),
                    description: description.isEmpty ? nil : description,
                    emoji: emoji.isEmpty ? nil : emoji,
                    visibility: visibility,
                    contributionMode: "open",
                    categories: Array(selectedCategories)
                ))
                title = ""
                description = ""
                selectedCategories = []
            } catch let err {
                error = err.localizedDescription
            }
            saving = false
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

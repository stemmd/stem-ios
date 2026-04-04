import SwiftUI

struct CategorySelectionSection: View {
    @Binding var selectedCategories: Set<String>
    var max: Int = 3

    var body: some View {
        Section("Category") {
            Text("\(selectedCategories.count)/\(max) selected")
                .font(.mono(DS.FontSize.caption))
                .foregroundStyle(Color.inkLight)

            FlowLayout(spacing: 6) {
                ForEach(allCategories) { cat in
                    CategoryPill(
                        category: cat,
                        isSelected: selectedCategories.contains(cat.id)
                    ) {
                        if selectedCategories.contains(cat.id) {
                            selectedCategories.remove(cat.id)
                        } else if selectedCategories.count < max {
                            selectedCategories.insert(cat.id)
                        }
                    }
                }
            }
        }
    }
}

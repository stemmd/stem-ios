import SwiftUI

struct ExploreView: View {
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Discover stems and people")
                    .font(.custom("DMSans-Regular", size: 15))
                    .foregroundStyle(Color("InkLight"))
                    .padding(.top, 40)
            }
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: "Search stems and people")
        }
    }
}

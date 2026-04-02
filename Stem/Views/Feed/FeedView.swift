import SwiftUI

struct FeedView: View {
    @State private var finds: [Find] = []
    @State private var hasMore = false
    @State private var loading = true

    var body: some View {
        NavigationStack {
            ScrollView {
                if loading && finds.isEmpty {
                    ProgressView()
                        .padding(.top, 60)
                } else if finds.isEmpty {
                    VStack(spacing: 12) {
                        Text("Your feed is quiet")
                            .font(.custom("DMSerifDisplay-Regular", size: 24))
                            .foregroundStyle(Color("Ink"))
                        Text("Follow some stems or people to see finds here.")
                            .font(.custom("DMSans-Regular", size: 15))
                            .foregroundStyle(Color("InkLight"))
                    }
                    .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(finds) { find in
                            FeedCardView(find: find)
                        }
                        if hasMore {
                            ProgressView()
                                .onAppear { loadMore() }
                                .padding()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Feed")
            .refreshable { await load() }
        }
        .task { await load() }
    }

    private func load() async {
        loading = true
        do {
            let res = try await APIClient.shared.getFeed()
            finds = res.finds
            hasMore = res.hasMore
        } catch {}
        loading = false
    }

    private func loadMore() {
        guard let last = finds.last?.createdAt else { return }
        Task {
            do {
                let res = try await APIClient.shared.getFeed(before: last)
                finds.append(contentsOf: res.finds)
                hasMore = res.hasMore
            } catch {}
        }
    }
}

struct FeedCardView: View {
    let find: Find

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Attribution
            HStack(spacing: 6) {
                Text("@\(find.contributorUsername ?? "")")
                    .font(.custom("DMMono-Regular", size: 12))
                    .foregroundStyle(Color("InkMid"))
                Text("added to")
                    .font(.custom("DMSans-Regular", size: 12))
                    .foregroundStyle(Color("InkLight"))
                Text("\(find.stemEmoji ?? "") \(find.stemTitle ?? "")")
                    .font(.custom("DMSans-Medium", size: 12))
                    .foregroundStyle(Color("Ink"))
                    .lineLimit(1)
            }

            // Find content
            VStack(alignment: .leading, spacing: 4) {
                if let title = find.title, !title.isEmpty {
                    Text(title)
                        .font(.custom("DMSans-SemiBold", size: 14))
                        .foregroundStyle(Color("Ink"))
                        .lineLimit(2)
                }
                if let domain = find.url.domain {
                    Text(domain)
                        .font(.custom("DMMono-Regular", size: 11))
                        .foregroundStyle(Color("InkLight"))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("Paper"))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let note = find.note, !note.isEmpty {
                Text(note)
                    .font(.custom("DMSans-Regular", size: 13))
                    .foregroundStyle(Color("InkMid"))
                    .italic()
            }
        }
        .padding(16)
        .background(Color("Surface"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color("PaperDark"), lineWidth: 1))
    }
}

extension String {
    var domain: String? {
        guard let url = URL(string: self), let host = url.host else { return nil }
        return host.replacingOccurrences(of: "www.", with: "")
    }
}

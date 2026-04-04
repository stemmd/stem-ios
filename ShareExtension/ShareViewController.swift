import SwiftUI
import UniformTypeIdentifiers

@objc(ShareViewController)
class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingView = UIHostingController(rootView: ShareView(
            extensionContext: extensionContext
        ))
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hostingView.didMove(toParent: self)
    }
}

// MARK: - Share View

private let forestColor = Color(UIColor(red: 0.176, green: 0.353, blue: 0.239, alpha: 1)) // #2D5A3D

struct ShareView: View {
    let extensionContext: NSExtensionContext?

    @State private var url: String = ""
    @State private var pageTitle: String = ""
    @State private var note: String = ""
    @State private var stems: [ShareStem] = []
    @State private var selectedStemId: String = ""
    @State private var saving = false
    @State private var saved = false
    @State private var error: String?
    @State private var loading = true

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if loading {
                    Spacer()
                    ProgressView()
                        .tint(forestColor)
                    Spacer()
                } else if saved {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(forestColor)
                        Text("Saved!")
                            .font(.custom("DMSans-SemiBold", size: 18))
                    }
                    Spacer()
                } else {
                    Form {
                        Section {
                            if !pageTitle.isEmpty {
                                Text(pageTitle)
                                    .font(.custom("DMSans-SemiBold", size: 14))
                                    .lineLimit(2)
                            }
                            Text(url)
                                .font(.custom("DMMono-Regular", size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }

                        Section("Save to stem") {
                            if stems.isEmpty {
                                Text("No stems found. Create one in the app first.")
                                    .font(.custom("DMSans-Regular", size: 13))
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Stem", selection: $selectedStemId) {
                                    Text("Select a stem...").tag("")
                                    ForEach(stems) { stem in
                                        Text("\(stem.emoji ?? "") \(stem.title)").tag(stem.id)
                                    }
                                }
                                .font(.custom("DMSans-Regular", size: 14))
                            }
                        }

                        Section("Note (optional)") {
                            TextField("Why is this interesting?", text: $note, axis: .vertical)
                                .font(.custom("DMSans-Regular", size: 14))
                                .lineLimit(3...5)
                        }

                        if let error {
                            Text(error)
                                .font(.custom("DMSans-Regular", size: 13))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Stem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { close() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "Saving..." : "Save") { save() }
                        .disabled(selectedStemId.isEmpty || saving || saved)
                        .foregroundStyle(forestColor)
                }
            }
        }
        .tint(forestColor)
        .task { await extractURL() }
    }

    private func extractURL() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            loading = false
            return
        }

        for item in items {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier),
                       let sharedURL = item as? URL {
                        url = sharedURL.absoluteString
                        pageTitle = sharedURL.host ?? ""
                    }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
                       let text = item as? String, text.hasPrefix("http") {
                        url = text
                    }
                }
            }
        }

        await loadStems()
        loading = false
    }

    private func loadStems() async {
        guard let token = readToken() else { return }
        guard let apiURL = URL(string: "https://api.stem.md/stems") else { return }

        var request = URLRequest(url: apiURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ShareStemsResponse.self, from: data)
            stems = response.stems
            if let first = stems.first { selectedStemId = first.id }
        } catch {}
    }

    private func save() {
        guard !selectedStemId.isEmpty, !url.isEmpty else { return }
        guard let token = readToken() else {
            error = "Please sign in to the Stem app first."
            return
        }
        saving = true
        error = nil

        Task {
            guard let apiURL = URL(string: "https://api.stem.md/stems/\(selectedStemId)/finds") else { return }
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any?] = ["url": url, "note": note.isEmpty ? nil : note]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body.compactMapValues { $0 })

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, http.statusCode < 300 {
                    // Success haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    saved = true
                    try? await Task.sleep(for: .seconds(1))
                    close()
                } else {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    error = "Failed to save. Try again."
                }
            } catch {
                self.error = "Network error. Check your connection."
            }
            saving = false
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func readToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "md.stem.app",
            kSecAttrAccount as String: "stem_token",
            kSecAttrAccessGroup as String: "group.md.stem",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

// MARK: - Local models (self-contained, no main app dependency)

struct ShareStem: Codable, Identifiable {
    let id: String
    let title: String
    let emoji: String?
    let slug: String
}

struct ShareStemsResponse: Codable {
    let stems: [ShareStem]
}

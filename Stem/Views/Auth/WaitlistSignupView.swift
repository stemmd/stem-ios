import SwiftUI

struct WaitlistSignupView: View {
    @Binding var isPresented: Bool
    var prefillEmail: String = ""

    @State private var username = ""
    @State private var email: String
    @State private var saving = false
    @State private var checkTask: Task<Void, Never>?

    init(isPresented: Binding<Bool>, prefillEmail: String = "") {
        _isPresented = isPresented
        _email = State(initialValue: prefillEmail)
    }
    @State private var usernameAvailable: Bool?
    @State private var success = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    VStack(spacing: DS.Spacing.sm) {
                        Text("Join the waitlist")
                            .font(.heading(DS.FontSize.title))
                            .foregroundStyle(Color.ink)

                        Text("Pick a username and we'll save your spot")
                            .font(.body(DS.FontSize.body))
                            .foregroundStyle(Color.inkMid)
                    }
                    .padding(.top, DS.Spacing.xl)

                    if success {
                        successView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, DS.Spacing.xl)
            }
            .background(Color.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

    private var formView: some View {
        VStack(spacing: DS.Spacing.md) {
            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Username")
                    .font(.body(DS.FontSize.small, weight: .semibold))
                    .foregroundStyle(Color.inkMid)

                HStack {
                    Text("stem.md/")
                        .font(.mono(DS.FontSize.body))
                        .foregroundStyle(Color.inkLight)
                    TextField("username", text: $username)
                        .font(.mono(DS.FontSize.body))
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: username) { checkUsername() }
                }
                .padding(12)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.small)
                        .strokeBorder(usernameAvailable == false ? Color.taken : Color.paperDark, lineWidth: 1)
                )

                if let available = usernameAvailable {
                    Text(available ? "Available" : "Taken")
                        .font(.mono(DS.FontSize.caption))
                        .foregroundStyle(available ? Color.forest : Color.taken)
                }
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text("Email")
                    .font(.body(DS.FontSize.small, weight: .semibold))
                    .foregroundStyle(Color.inkMid)

                StemTextField(placeholder: "you@email.com", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            if let error {
                Text(error)
                    .font(.body(DS.FontSize.small))
                    .foregroundStyle(Color.taken)
            }

            StemButton(
                title: saving ? "Joining..." : "Join the waitlist",
                fullWidth: true,
                isLoading: saving
            ) {
                signup()
            }
            .disabled(username.count < 3 || !email.contains("@") || usernameAvailable != true || saving)
        }
    }

    private var successView: some View {
        VStack(spacing: DS.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.forest)

            Text("You're on the list")
                .font(.heading(DS.FontSize.headingLarge))
                .foregroundStyle(Color.ink)

            Text("stem.md/\(username) is reserved for you")
                .font(.mono(DS.FontSize.body))
                .foregroundStyle(Color.inkMid)

            Text("We'll email you when it's your turn")
                .font(.body(DS.FontSize.body))
                .foregroundStyle(Color.inkLight)

            StemButton(title: "Done", style: .secondary) {
                isPresented = false
            }
            .padding(.top, DS.Spacing.sm)
        }
        .padding(.top, DS.Spacing.xl)
    }

    private func checkUsername() {
        let clean = username.lowercased().trimmingCharacters(in: .whitespaces)
        guard clean.count >= 3 else { usernameAvailable = nil; return }

        checkTask?.cancel()
        checkTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let url = URL(string: "https://api.stem.md/check?username=\(clean)")!
                let (data, _) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled else { return }
                let result = try JSONDecoder().decode(CheckResponse.self, from: data)
                usernameAvailable = result.available
            } catch {
                if !Task.isCancelled { usernameAvailable = nil }
            }
        }
    }

    private func signup() {
        saving = true
        error = nil
        Task {
            do {
                var request = URLRequest(url: URL(string: "https://api.stem.md/signup")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let body: [String: String] = [
                    "username": username.lowercased().trimmingCharacters(in: .whitespaces),
                    "email": email.lowercased().trimmingCharacters(in: .whitespaces),
                    "platform": "ios"
                ]
                request.httpBody = try JSONEncoder().encode(body)
                let (data, _) = try await URLSession.shared.data(for: request)
                let result = try JSONDecoder().decode(SignupResponse.self, from: data)
                if result.success == true {
                    Haptic.play(.saved)
                    success = true
                } else {
                    Haptic.play(.error)
                    error = result.error == "username_taken" ? "That username is taken" :
                            result.error == "email_taken" ? "That email is already registered" :
                            result.error ?? "Something went wrong"
                }
            } catch {
                Haptic.play(.error)
                self.error = "Network error. Check your connection"
            }
            saving = false
        }
    }
}

private struct CheckResponse: Decodable { let available: Bool }
private struct SignupResponse: Decodable { let success: Bool?; let error: String? }

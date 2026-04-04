import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var authService = AuthService()
    @State private var showWaitlist = false
    @State private var waitlistEmail = ""
    @State private var googleLoading = false
    @State private var webAuthSession: ASWebAuthenticationSession?
    @State private var webAuthContext = WebAuthContext()

    // Review mode
    @State private var reviewMode = false
    @State private var reviewUsername = ""
    @State private var reviewPassword = ""
    @State private var reviewLoading = false
    @State private var reviewError: String?

    var body: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()

            // Logo
            Image("StemLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.large))

            Text("Stem")
                .font(.heading(32))
                .foregroundStyle(Color.ink)

            Text("A home for your curiosity")
                .font(.body(16))
                .foregroundStyle(Color.inkMid)

            Spacer()

            VStack(spacing: 12) {
                // Review mode: username + password
                if reviewMode {
                    TextField("Username", text: $reviewUsername)
                        .font(.mono(DS.FontSize.body))
                        .padding(14)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.small).strokeBorder(Color.paperDark, lineWidth: 1))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textContentType(.username)

                    SecureField("Password", text: $reviewPassword)
                        .font(.mono(DS.FontSize.body))
                        .padding(14)
                        .background(Color.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                        .overlay(RoundedRectangle(cornerRadius: DS.Radius.small).strokeBorder(Color.paperDark, lineWidth: 1))
                        .textContentType(.password)

                    StemButton(title: reviewLoading ? "Signing in..." : "Sign in", fullWidth: true, isLoading: reviewLoading) {
                        reviewSignIn()
                    }
                    .disabled(reviewUsername.isEmpty || reviewPassword.isEmpty || reviewLoading)

                    if let reviewError {
                        Text(reviewError)
                            .font(.body(DS.FontSize.small))
                            .foregroundStyle(Color.taken)
                    }
                }

                // Sign in with Apple
                Button {
                    Task {
                        let success = await authService.signInWithApple()
                        if !success, let err = authService.error, err.hasPrefix("no_account:") {
                            waitlistEmail = String(err.dropFirst("no_account:".count))
                            showWaitlist = true
                            authService.error = nil
                        }
                    }
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        if authService.isLoading {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Image(systemName: "apple.logo")
                        Text(authService.isLoading ? "Signing in..." : "Sign in with Apple")
                    }
                    .font(.body(DS.FontSize.bodyLarge, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.ink)
                    .foregroundStyle(Color.paper)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                }
                .disabled(authService.isLoading || googleLoading)

                // Sign in with Google
                Button {
                    signInWithGoogle()
                } label: {
                    HStack(spacing: DS.Spacing.sm) {
                        if googleLoading {
                            ProgressView().tint(Color.ink).scaleEffect(0.8)
                        }
                        Image(systemName: "globe")
                        Text(googleLoading ? "Signing in..." : "Sign in with Google")
                    }
                    .font(.body(DS.FontSize.bodyLarge, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.surface)
                    .foregroundStyle(Color.ink)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.small))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.small)
                            .strokeBorder(Color.paperDark, lineWidth: 1)
                    )
                }
                .disabled(authService.isLoading || googleLoading)
            }

            // Error message
            if let error = authService.error, !error.hasPrefix("no_account:") {
                Text(error)
                    .font(.body(DS.FontSize.small))
                    .foregroundStyle(Color.taken)
                    .multilineTextAlignment(.center)
            }

            // Waitlist link
            Button {
                showWaitlist = true
            } label: {
                Text("New here? Join the waitlist")
                    .font(.body(DS.FontSize.body))
                    .foregroundStyle(Color.forest)
            }

            Text("By signing in, you agree to our Terms and Privacy Policy")
                .font(.body(12))
                .foregroundStyle(Color.inkLight)
                .multilineTextAlignment(.center)

            Spacer().frame(height: DS.Spacing.md)
        }
        .padding(DS.Spacing.xl)
        .background(Color.paper)
        .sheet(isPresented: $showWaitlist) {
            WaitlistSignupView(isPresented: $showWaitlist, prefillEmail: waitlistEmail)
        }
        .task { await checkReviewMode() }
    }

    private func checkReviewMode() async {
        // Check if review mode is enabled on the API
        do {
            var request = URLRequest(url: URL(string: "https://api.stem.md/auth/review")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(["username": "", "password": ""])
            let (data, _) = try await URLSession.shared.data(for: request)
            // If we get "missing_credentials" back, review mode is on
            // If we get "Not available", review mode is off
            if let json = try? JSONDecoder().decode([String: String].self, from: data) {
                reviewMode = json["error"] == "missing_credentials"
            }
        } catch {}
    }

    private func reviewSignIn() {
        reviewLoading = true
        reviewError = nil
        Task {
            do {
                struct ReviewBody: Encodable { let username: String; let password: String }
                struct ReviewResponse: Decodable { let token: String?; let error: String? }

                var request = URLRequest(url: URL(string: "https://api.stem.md/auth/review")!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(ReviewBody(username: reviewUsername, password: reviewPassword))
                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(ReviewResponse.self, from: data)

                if let token = response.token {
                    APIClient.shared.token = token
                    Haptic.play(.saved)
                } else {
                    reviewError = response.error ?? "Sign in failed"
                }
            } catch {
                reviewError = "Network error"
            }
            reviewLoading = false
        }
    }

    private func signInWithGoogle() {
        guard let authURL = URL(string: "https://stem.md/auth/google?mobile=1") else { return }
        googleLoading = true

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "stem"
        ) { callbackURL, error in
            DispatchQueue.main.async {
                googleLoading = false
                webAuthSession = nil
                guard let callbackURL, error == nil else { return }
                if let token = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "token" })?.value {
                    APIClient.shared.token = token
                    Haptic.play(.saved)
                    Analytics.track("sign_in_google")
                }
            }
        }
        session.presentationContextProvider = webAuthContext
        session.prefersEphemeralWebBrowserSession = true
        webAuthSession = session
        session.start()
    }
}

final class WebAuthContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

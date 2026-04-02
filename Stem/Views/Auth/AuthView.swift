import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var loading = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("Forest"))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "leaf")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    )

                Text("stem")
                    .font(.custom("DMSerifDisplay-Regular", size: 32))
                    .foregroundStyle(Color("Ink"))
            }

            Text("Curate what you're into.")
                .font(.custom("DMSans-Regular", size: 16))
                .foregroundStyle(Color("InkMid"))

            Spacer()

            // Sign in with Google (via web OAuth)
            Button {
                signInWithWeb()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                }
                .font(.custom("DMSans-Medium", size: 15))
                .frame(maxWidth: .infinity)
                .padding(14)
                .background(Color("Forest"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text("By signing in, you agree to our Terms and Privacy Policy.")
                .font(.custom("DMSans-Regular", size: 12))
                .foregroundStyle(Color("InkLight"))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 24)
        }
        .padding(32)
        .background(Color("Paper"))
    }

    private func signInWithWeb() {
        // Opens ASWebAuthenticationSession for Google OAuth
        // The server handles the OAuth flow and returns a session token
        guard let authURL = URL(string: "https://stem.md/auth/google?mobile=1") else { return }
        loading = true

        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "stem"
        ) { callbackURL, error in
            loading = false
            guard let callbackURL, error == nil else { return }
            // Extract token from callback: stem://auth?token=<session_id>
            if let token = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "token" })?.value {
                APIClient.shared.token = token
            }
        }
        session.prefersEphemeralWebBrowserSession = false
        session.start()
    }
}

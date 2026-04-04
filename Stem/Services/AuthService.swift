import AuthenticationServices
import Foundation

@Observable
final class AuthService: NSObject {
    var error: String?
    var isLoading = false

    private var continuation: CheckedContinuation<ASAuthorization, Error>?

    func signInWithApple() async -> Bool {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let authorization = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ASAuthorization, Error>) in
                continuation = cont
                let request = ASAuthorizationAppleIDProvider().createRequest()
                request.requestedScopes = [.email, .fullName]
                let controller = ASAuthorizationController(authorizationRequests: [request])
                controller.delegate = self
                controller.performRequests()
            }

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                error = "Could not get Apple credentials"
                return false
            }

            // Build full name if Apple provided it (only on first sign-in)
            var fullName: String?
            if let given = credential.fullName?.givenName {
                fullName = [given, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
            }

            // Send to our API
            return try await authenticateWithAPI(identityToken: identityToken, fullName: fullName)
        } catch let err as ASAuthorizationError where err.code == .canceled {
            return false
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    private func authenticateWithAPI(identityToken: String, fullName: String?) async throws -> Bool {
        struct AppleAuthBody: Encodable {
            let identityToken: String
            let fullName: String?
        }
        struct AppleAuthResponse: Decodable {
            let token: String?
            let user: AuthUser?
            let isNew: Bool?
            let error: String?
            let email: String?
        }
        struct AuthUser: Decodable {
            let id: String
            let username: String
        }

        var request = URLRequest(url: URL(string: "https://api.stem.md/auth/apple")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AppleAuthBody(identityToken: identityToken, fullName: fullName))

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AppleAuthResponse.self, from: data)

        if let token = response.token {
            APIClient.shared.token = token
            Haptic.play(.saved)
            Analytics.track("sign_in_apple")
            return true
        }

        // Handle specific errors
        switch response.error {
        case "not_invited_yet":
            error = "You're on the waitlist! We'll let you know when it's your turn"
        case "no_account":
            error = "no_account:\(response.email ?? "")"
        default:
            error = response.error ?? "Sign in failed"
        }
        return false
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

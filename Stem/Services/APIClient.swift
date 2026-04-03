import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in to continue."
        case .notFound: return "Not found."
        case .serverError(let msg): return msg
        case .networkError(let err): return err.localizedDescription
        }
    }
}

@Observable
final class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://api.stem.md"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    var token: String? {
        get { KeychainHelper.read(key: "stem_token") }
        set {
            if let newValue {
                KeychainHelper.save(key: "stem_token", value: newValue)
            } else {
                KeychainHelper.delete(key: "stem_token")
            }
        }
    }

    var isAuthenticated: Bool { token != nil }

    // MARK: - Generic request

    private func request<T: Decodable>(
        _ method: String,
        path: String,
        body: (any Encodable)? = nil,
        query: [String: String] = [:]
    ) async throws -> T {
        var components = URLComponents(string: "\(baseURL)\(path)")!
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: req)
        let http = response as! HTTPURLResponse

        switch http.statusCode {
        case 200...299:
            return try decoder.decode(T.self, from: data)
        case 401:
            token = nil
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            if let err = try? decoder.decode([String: String].self, from: data), let msg = err["error"] {
                throw APIError.serverError(msg)
            }
            throw APIError.serverError("Something went wrong.")
        }
    }

    // MARK: - Feed

    func getFeed(before: String? = nil) async throws -> FeedResponse {
        var query: [String: String] = [:]
        if let before { query["before"] = before }
        return try await request("GET", path: "/feed", query: query)
    }

    // MARK: - Stems

    func getMyStems() async throws -> StemsResponse {
        return try await request("GET", path: "/stems")
    }

    func createStem(_ body: CreateStemBody) async throws -> CreateStemResponse {
        return try await request("POST", path: "/stems", body: body)
    }

    func getStemDetail(id: String) async throws -> StemDetailResponse {
        return try await request("GET", path: "/stems/\(id)")
    }

    // MARK: - Finds

    func addFind(stemId: String, body: AddFindBody) async throws -> AddFindResponse {
        return try await request("POST", path: "/stems/\(stemId)/finds", body: body)
    }

    // MARK: - Social

    func getUserProfile(username: String) async throws -> UserProfileResponse {
        return try await request("GET", path: "/users/\(username)")
    }

    func followUser(id: String) async throws -> SuccessResponse {
        return try await request("POST", path: "/users/\(id)/follow", body: ["action": "follow"])
    }

    func unfollowUser(id: String) async throws -> SuccessResponse {
        return try await request("POST", path: "/users/\(id)/follow", body: ["action": "unfollow"])
    }

    func followStem(id: String) async throws -> SuccessResponse {
        return try await request("POST", path: "/stems/\(id)/follow", body: ["action": "follow"])
    }

    func unfollowStem(id: String) async throws -> SuccessResponse {
        return try await request("POST", path: "/stems/\(id)/follow", body: ["action": "unfollow"])
    }

    // MARK: - Notifications

    func getNotifications(before: String? = nil) async throws -> NotificationsResponse {
        var query: [String: String] = [:]
        if let before { query["before"] = before }
        return try await request("GET", path: "/notifications", query: query)
    }

    func markNotificationsRead() async throws -> SuccessResponse {
        return try await request("POST", path: "/notifications")
    }
}

// MARK: - Response types

struct FeedResponse: Codable {
    let finds: [Find]
    let hasMore: Bool
}

struct StemsResponse: Codable {
    let stems: [Stem]
}

struct CreateStemBody: Codable {
    let title: String
    let description: String?
    let emoji: String?
    let visibility: String
    let contributionMode: String?
    let categories: [String]

    enum CodingKeys: String, CodingKey {
        case title, description, emoji, visibility, categories
        case contributionMode = "contribution_mode"
    }
}

struct CreateStemResponse: Codable {
    let id: String
    let slug: String
    let username: String
}

struct AddFindBody: Codable {
    let url: String
    let note: String?
    let title: String?
    let description: String?
    let sourceType: String?

    enum CodingKeys: String, CodingKey {
        case url, note, title, description
        case sourceType = "source_type"
    }
}

struct AddFindResponse: Codable {
    let id: String
    let pending: Bool
}

struct StemDetailResponse: Codable {
    let stem: Stem
    let finds: [Find]
    let followerCount: Int
    let isFollowing: Bool
    let isOwner: Bool
}

struct UserProfileResponse: Codable {
    let user: User
    let stems: [Stem]
    let followerCount: Int
    let followingCount: Int
    let isFollowing: Bool
    let isOwner: Bool
}

struct NotificationsResponse: Codable {
    let notifications: [StemNotification]
    let unreadCount: Int
}

struct SuccessResponse: Codable {
    let success: Bool?
}

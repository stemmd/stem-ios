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
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        config.timeoutIntervalForRequest = 15
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()
    private let decoder = JSONDecoder()

    // Stored property so @Observable tracks changes for UI updates.
    // Synced to Keychain for persistence across app launches.
    var token: String? = KeychainHelper.read(key: "stem_token") {
        didSet {
            if let token {
                KeychainHelper.save(key: "stem_token", value: token)
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
        return try await request("POST", path: "/notifications/read")
    }

    // MARK: - Notification Count

    func getNotificationCount() async throws -> NotificationCountResponse {
        return try await request("GET", path: "/notifications/count")
    }

    // MARK: - OG Metadata

    func getOGMetadata(url: String) async throws -> OGMetadataResponse {
        return try await request("GET", path: "/og", query: ["url": url])
    }

    // MARK: - User Profile

    func getCurrentUser() async throws -> CurrentUserResponse {
        return try await request("GET", path: "/me")
    }

    // MARK: - Stem Edit

    func updateStem(id: String, body: UpdateStemBody) async throws -> SuccessResponse {
        return try await request("PUT", path: "/stems/\(id)", body: body)
    }

    func deleteStem(id: String) async throws -> SuccessResponse {
        return try await request("DELETE", path: "/stems/\(id)")
    }

    func deleteFind(stemId: String, findId: String) async throws -> SuccessResponse {
        return try await request("DELETE", path: "/stems/\(stemId)/finds/\(findId)")
    }

    func updateFindStatus(stemId: String, findId: String, status: String) async throws -> SuccessResponse {
        return try await request("PUT", path: "/stems/\(stemId)/finds/\(findId)", body: ["status": status])
    }

    // MARK: - Profile Edit

    func updateProfile(body: UpdateProfileBody) async throws -> CurrentUserResponse {
        return try await request("PUT", path: "/me", body: body)
    }

    func getFollowers(username: String) async throws -> FollowersResponse {
        return try await request("GET", path: "/users/\(username)/followers")
    }

    func getFollowing(username: String) async throws -> FollowingResponse {
        return try await request("GET", path: "/users/\(username)/following")
    }

    // MARK: - Stem Followers

    func getStemFollowers(stemId: String) async throws -> FollowersResponse {
        return try await request("GET", path: "/stems/\(stemId)/followers")
    }

    // MARK: - Explore

    func getExplore() async throws -> ExploreResponse {
        return try await request("GET", path: "/explore")
    }

    func getExploreCategory(categoryId: String, offset: Int = 0) async throws -> CategoryStemsResponse {
        return try await request("GET", path: "/explore", query: ["cat": categoryId, "offset": String(offset)])
    }

    func search(query: String) async throws -> SearchResponse {
        return try await request("GET", path: "/explore/search", query: ["q": query])
    }

    // MARK: - Sign Out

    func signOut() {
        token = nil
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
    let categories: [String]?
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

struct NotificationCountResponse: Codable {
    let count: Int
}

struct OGMetadataResponse: Codable {
    let title: String?
    let description: String?
    let image: String?
    let favicon: String?
    let domain: String?
    let sourceType: String?
    let embedUrl: String?

    enum CodingKeys: String, CodingKey {
        case title, description, image, favicon, domain
        case sourceType = "source_type"
        case embedUrl = "embed_url"
    }
}

struct UpdateStemBody: Codable {
    var title: String?
    var description: String?
    var emoji: String?
    var visibility: String?
    var contributionMode: String?
    var categories: [String]?

    enum CodingKeys: String, CodingKey {
        case title, description, emoji, visibility, categories
        case contributionMode = "contribution_mode"
    }
}

struct CurrentUserResponse: Codable {
    let user: User
}

struct ExploreResponse: Codable {
    let trending: [Stem]
    let categories: [CategoryCount]
    let topUsers: [User]
}

struct CategoryCount: Codable, Identifiable {
    let id: String
    let stemCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case stemCount = "stem_count"
    }
}

struct CategoryStemsResponse: Codable {
    let stems: [Stem]
}

struct SearchResponse: Codable {
    let stems: [Stem]
    let users: [User]
}

struct UpdateProfileBody: Codable {
    var displayName: String?
    var bio: String?
    var website: String?
    var twitter: String?

    enum CodingKeys: String, CodingKey {
        case bio, website, twitter
        case displayName = "display_name"
    }
}

struct FollowersResponse: Codable {
    let users: [User]
    let count: Int
}

struct FollowingResponse: Codable {
    let users: [User]
    let stems: [Stem]
    let userCount: Int
    let stemCount: Int
}

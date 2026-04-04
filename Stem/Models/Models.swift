import Foundation

// MARK: - Enums

enum Visibility: String, Codable, Hashable {
    case `public` = "public"
    case mutuals = "mutuals"
    case `private` = "private"
}

enum ContributionMode: String, Codable, Hashable {
    case open = "open"
    case mutuals = "mutuals"
    case closed = "closed"
}

enum NotificationType: String, Codable, Hashable {
    case newFollower = "new_follower"
    case stemFollowed = "stem_followed"
    case newFind = "new_find"
    case findApproved = "find_approved"
}

enum Appearance: String, CaseIterable {
    case system, light, dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

import SwiftUI

// MARK: - Models

struct User: Codable, Identifiable, Hashable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    let bio: String?
    let website: String?
    let twitter: String?
    let mastodon: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, bio, website, twitter, mastodon
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}

struct Stem: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let slug: String
    let description: String?
    let emoji: String?
    let visibility: Visibility
    let contributionMode: ContributionMode?
    let isGrove: Int?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let userId: String?
    let username: String?
    let displayName: String?
    let avatarUrl: String?
    let findCount: Int?
    let primaryCategory: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, description, emoji, visibility, status, username
        case contributionMode = "contribution_mode"
        case isGrove = "is_grove"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case findCount = "find_count"
        case primaryCategory = "primary_category"
    }

    var isBranch: Bool { isGrove == 1 }
}

struct Find: Codable, Identifiable, Hashable {
    let id: String
    let url: String
    let title: String?
    let description: String?
    let imageUrl: String?
    let faviconUrl: String?
    let note: String?
    let sourceType: String?
    let createdAt: String?
    let contributorUsername: String?

    // Feed-specific fields
    let stemTitle: String?
    let stemSlug: String?
    let stemUsername: String?
    let stemEmoji: String?
    let stemId: String?
    let stemCategory: String?
    let contributorDisplayName: String?
    let contributorAvatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, url, title, description, note
        case imageUrl = "image_url"
        case faviconUrl = "favicon_url"
        case sourceType = "source_type"
        case createdAt = "created_at"
        case contributorUsername = "contributor_username"
        case stemTitle = "stem_title"
        case stemSlug = "stem_slug"
        case stemUsername = "stem_username"
        case stemEmoji = "stem_emoji"
        case stemId = "stem_id"
        case stemCategory = "stem_category"
        case contributorDisplayName = "contributor_display_name"
        case contributorAvatarUrl = "contributor_avatar_url"
    }
}

struct StemNotification: Codable, Identifiable, Hashable {
    let id: String
    let type: NotificationType
    let actorId: String?
    let stemId: String?
    let findId: String?
    let read: Int
    let createdAt: String
    let actorUsername: String
    let actorDisplayName: String?
    let actorAvatarUrl: String?
    let stemTitle: String?
    let stemSlug: String?
    let stemOwnerUsername: String?
    let findTitle: String?

    enum CodingKeys: String, CodingKey {
        case id, type, read
        case actorId = "actor_id"
        case stemId = "stem_id"
        case findId = "find_id"
        case createdAt = "created_at"
        case actorUsername = "actor_username"
        case actorDisplayName = "actor_display_name"
        case actorAvatarUrl = "actor_avatar_url"
        case stemTitle = "stem_title"
        case stemSlug = "stem_slug"
        case stemOwnerUsername = "stem_owner_username"
        case findTitle = "find_title"
    }

    var isUnread: Bool { read == 0 }
}

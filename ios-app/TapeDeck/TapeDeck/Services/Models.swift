import Foundation

// MARK: - Track Model
struct Track: Codable, Identifiable {
    let id = UUID()
    let timestamp: String
    let artist: String
    let title: String
    let sourceRank: Int

    enum CodingKeys: String, CodingKey {
        case timestamp
        case artist
        case title
        case sourceRank = "source_rank"
    }
}

// MARK: - Generation Request/Response
struct GenerationRequest: Codable {
    let date: String
    let genre: String
    let hours: Int
    let repeatGapMin: Int
    let seed: String?
    let limit: Int = 500

    enum CodingKeys: String, CodingKey {
        case date
        case genre
        case hours
        case repeatGapMin = "repeat_gap_min"
        case seed
        case limit
    }
}

struct GenerationResponse: Codable {
    let tracks: [Track]
}

// MARK: - YouTube Resolution
struct YouTubeResolutionRequest: Codable {
    let tracks: [YouTubeTrack]
    let limit: Int

    struct YouTubeTrack: Codable {
        let artist: String
        let title: String
    }
}

struct YouTubeResolutionResponse: Codable {
    let ids: [String]
}

// MARK: - Apple Music
struct AppleMusicCreatePlaylistRequest: Codable {
    let userToken: String
    let name: String
    let tracks: [PlaylistTrack]

    struct PlaylistTrack: Codable {
        let artist: String
        let title: String
    }
}

struct AppleMusicCreatePlaylistResponse: Codable {
    let addedCount: Int
    let totalTracks: Int

    enum CodingKeys: String, CodingKey {
        case addedCount = "added_count"
        case totalTracks = "total_tracks"
    }
}

struct AppleMusicTokenResponse: Codable {
    let token: String
    let storefront: String
}

// MARK: - Analytics
struct AnalyticsEvent: Codable {
    let v: Int = 1
    let event: String
    let ts: String
    let anonUserId: String
    let sessionId: String
    let props: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case v
        case event
        case ts
        case anonUserId = "anon_user_id"
        case sessionId = "session_id"
        case props
    }
}

// MARK: - AnyCodable Helper
enum AnyCodable: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([AnyCodable])
    case object([String: AnyCodable])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([AnyCodable].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: AnyCodable].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let bool):
            try container.encode(bool)
        case .int(let int):
            try container.encode(int)
        case .double(let double):
            try container.encode(double)
        case .string(let string):
            try container.encode(string)
        case .array(let array):
            try container.encode(array)
        case .object(let object):
            try container.encode(object)
        }
    }
}

// MARK: - Analytics Today Stats
struct AnalyticsTodayStats: Codable {
    let searches: Int
    let exports: Int
    let activeUsers: Int
    let successRate: Double

    enum CodingKeys: String, CodingKey {
        case searches
        case exports
        case activeUsers = "active_users"
        case successRate = "success_rate"
    }
}

import Foundation

class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "https://timedeck-api.onrender.com"
    private let timeoutSeconds = 180.0

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 180.0
        config.timeoutIntervalForResource = 180.0
        return URLSession(configuration: config)
    }()

    // MARK: - Playlist Generation

    func generatePlaylist(date: String, genre: String, hours: Int, repeatGapMin: Int, seed: String? = nil) async throws -> [Track] {
        let request = GenerationRequest(
            date: date,
            genre: genre,
            hours: hours,
            repeatGapMin: repeatGapMin,
            seed: seed
        )

        let response: GenerationResponse = try await post(
            endpoint: "/v1/simulate",
            body: request
        )

        return response.tracks
    }

    // MARK: - YouTube Resolution

    func resolveYouTubeVideos(tracks: [Track], limit: Int = 500) async throws -> [String] {
        let youtubeTrackRequest = YouTubeResolutionRequest.YouTubeTrack.self
        let tracks = tracks.map { YouTubeResolutionRequest.YouTubeTrack(artist: $0.artist, title: $0.title) }

        let request = YouTubeResolutionRequest(
            tracks: tracks,
            limit: limit
        )

        let response: YouTubeResolutionResponse = try await post(
            endpoint: "/v1/yt/resolve",
            body: request
        )

        return response.ids
    }

    // MARK: - Apple Music

    func getAppleMusicDevToken() async throws -> AppleMusicTokenResponse {
        return try await get(endpoint: "/v1/apple/dev-token")
    }

    func createAppleMusicPlaylist(
        userToken: String,
        name: String,
        tracks: [Track]
    ) async throws -> AppleMusicCreatePlaylistResponse {
        let playlistTracks = tracks.map { AppleMusicCreatePlaylistRequest.PlaylistTrack(artist: $0.artist, title: $0.title) }

        let request = AppleMusicCreatePlaylistRequest(
            userToken: userToken,
            name: name,
            tracks: playlistTracks
        )

        return try await post(endpoint: "/v1/apple/create-playlist", body: request)
    }

    // MARK: - Analytics

    func submitAnalyticsEvent(_ event: AnalyticsEvent) async throws {
        _ = try await post(
            endpoint: "/v1/events",
            body: event
        ) as AnyCodable
    }

    // MARK: - Private Helpers

    private func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = timeoutSeconds

        return try await performRequest(request)
    }

    private func post<T: Decodable, U: Encodable>(
        endpoint: String,
        body: U
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeoutSeconds

        request.httpBody = try JSONEncoder().encode(body)

        return try await performRequest(request)
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch is URLError {
            throw APIError.networkError
        } catch is DecodingError {
            throw APIError.decodingError
        }
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP Error: \(statusCode)"
        case .networkError:
            return "Network error. Please check your connection."
        case .decodingError:
            return "Failed to decode response from server"
        }
    }
}

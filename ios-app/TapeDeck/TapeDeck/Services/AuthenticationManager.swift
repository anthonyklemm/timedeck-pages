import Foundation
import MusicKit

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var appleMusicAuthorized = false
    @Published var appleMusicDevToken: String?
    @Published var appleMusicStorefront: String?

    @Published var isAuthenticating = false
    @Published var authError: String?

    private weak var storageManager: StorageManager?
    private let apiClient = APIClient.shared

    override init() {
        super.init()
        checkMusicKitAuthorization()
    }

    func setStorageManager(_ manager: StorageManager) {
        self.storageManager = manager
    }

    // MARK: - Apple Music MusicKit Authorization

    func checkMusicKitAuthorization() {
        Task {
            let status = await MusicAuthorization.request()
            DispatchQueue.main.async {
                self.appleMusicAuthorized = status == .authorized
                print("DEBUG AuthManager: MusicKit authorization status: \(status == .authorized)")
            }
        }
    }

    func requestMusicKitAuthorization() async -> Bool {
        print("DEBUG AuthManager: Requesting MusicKit authorization")
        let status = await MusicAuthorization.request()
        DispatchQueue.main.async {
            self.appleMusicAuthorized = status == .authorized
            print("DEBUG AuthManager: MusicKit authorization result: \(status == .authorized)")
        }
        return status == .authorized
    }

    // MARK: - Create Apple Music Playlist (Using REST API - Batch Approach)

    func createAppleMusicPlaylist(name: String, tracks: [Track]) async -> (success: Bool, message: String) {
        print("DEBUG AuthManager: createAppleMusicPlaylist called with \(tracks.count) tracks")

        // First, ensure we have authorization
        let authorized = await requestMusicKitAuthorization()
        guard authorized else {
            print("DEBUG AuthManager: User denied MusicKit authorization")
            return (false, "Apple Music access denied. Please enable in Settings.")
        }

        print("DEBUG AuthManager: User authorized, fetching dev token for REST API")

        do {
            // 1. Get dev token from backend
            let devTokenResponse = try await apiClient.getAppleMusicDevToken()
            let devToken = devTokenResponse.token
            let storefront = devTokenResponse.storefront ?? "us"

            print("DEBUG AuthManager: Got dev token, proceeding with REST API approach")

            // 2. Search for tracks using REST API and collect song IDs
            var songIdsToAdd: [(id: String, type: String)] = []
            var notFoundTracks: [String] = []

            print("DEBUG AuthManager: Searching for \(tracks.count) tracks via Apple Music REST API")

            for track in tracks {
                do {
                    let searchTerm = "\(track.artist) \(track.title)"
                    print("DEBUG AuthManager: Searching for '\(track.title)' by '\(track.artist)'")

                    let songId = try await searchAppleMusicTrack(
                        artist: track.artist,
                        title: track.title,
                        devToken: devToken,
                        storefront: storefront
                    )

                    if let songId = songId {
                        songIdsToAdd.append((id: songId, type: "songs"))
                        print("DEBUG AuthManager: Found track: \(track.title)")
                    } else {
                        notFoundTracks.append("\(track.title) by \(track.artist)")
                        print("DEBUG AuthManager: Could not find track: \(track.title)")
                    }

                    // Rate limiting
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                } catch {
                    print("DEBUG AuthManager: Error searching for track: \(error)")
                    notFoundTracks.append("\(track.title) by \(track.artist)")
                }
            }

            print("DEBUG AuthManager: Found \(songIdsToAdd.count)/\(tracks.count) tracks")

            guard !songIdsToAdd.isEmpty else {
                return (false, "Could not find any tracks in Apple Music catalog.")
            }

            // 3. Create empty playlist via REST API
            print("DEBUG AuthManager: Creating playlist via REST API: \(name)")
            let playlistId = try await createAppleMusicPlaylistViaREST(
                name: name,
                devToken: devToken
            )

            // 4. Batch add all tracks to playlist via REST API
            print("DEBUG AuthManager: Batch adding \(songIdsToAdd.count) tracks to playlist")
            let addedCount = try await batchAddTracksToPlaylist(
                playlistId: playlistId,
                songIds: songIdsToAdd,
                devToken: devToken
            )

            print("DEBUG AuthManager: Successfully created playlist with \(addedCount) tracks")

            var message = "Successfully created playlist '\(name)' with \(addedCount) tracks in Apple Music!"
            if notFoundTracks.count > 0 {
                message += "\n\n⚠️ Could not find \(notFoundTracks.count) track(s) in Apple Music"
            }

            return (true, message)

        } catch {
            print("DEBUG AuthManager: Error creating playlist: \(error)")
            return (false, "Error creating playlist: \(error.localizedDescription)")
        }
    }

    // MARK: - REST API Helper Methods

    private func searchAppleMusicTrack(
        artist: String,
        title: String,
        devToken: String,
        storefront: String
    ) async throws -> String? {
        let searchTerm = "\(artist) \(title)"
        let urlString = "https://api.music.apple.com/v1/catalog/\(storefront)/search"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: 1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 12

        let queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "types", value: "songs")
        ]
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        request.url = components?.url

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            print("DEBUG AuthManager: Search failed with status \(httpResponse.statusCode)")
            return nil
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(AppleMusicSearchResponse.self, from: data)

        if let songs = result.results?.songs?.data, !songs.isEmpty {
            return songs[0].id
        }

        return nil
    }

    private func createAppleMusicPlaylistViaREST(
        name: String,
        devToken: String
    ) async throws -> String {
        let urlString = "https://api.music.apple.com/v1/me/library/playlists"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: 1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let payload = [
            "attributes": [
                "name": name,
                "description": "Generated by TapeDeck Time Machine"
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("DEBUG AuthManager: Playlist creation failed with status \(httpResponse.statusCode): \(errorMsg)")
            throw NSError(domain: "PlaylistCreationFailed", code: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let result = try decoder.decode(AppleMusicPlaylistCreateResponse.self, from: data)

        guard let playlistId = result.data?.first?.id else {
            throw NSError(domain: "NoPlaylistID", code: 1)
        }

        return playlistId
    }

    private func batchAddTracksToPlaylist(
        playlistId: String,
        songIds: [(id: String, type: String)],
        devToken: String
    ) async throws -> Int {
        let urlString = "https://api.music.apple.com/v1/me/library/playlists/\(playlistId)/tracks"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: 1)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(devToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let payload = ["data": songIds.map { ["id": $0.id, "type": $0.type] }]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("DEBUG AuthManager: Adding tracks failed with status \(httpResponse.statusCode): \(errorMsg)")
            throw NSError(domain: "AddTracksFailed", code: httpResponse.statusCode)
        }

        print("DEBUG AuthManager: Successfully batch added \(songIds.count) tracks")
        return songIds.count
    }

    // MARK: - Dev Token (for future use or reference)

    func fetchAppleMusicDevToken() async {
        print("DEBUG AuthManager: fetchAppleMusicDevToken called")
        isAuthenticating = true
        authError = nil

        do {
            print("DEBUG AuthManager: Calling API to get dev token")
            let response = try await apiClient.getAppleMusicDevToken()
            print("DEBUG AuthManager: API response received - token length: \(response.token.count), storefront: \(response.storefront)")
            DispatchQueue.main.async {
                self.appleMusicDevToken = response.token
                self.appleMusicStorefront = response.storefront
                self.isAuthenticating = false
                print("DEBUG AuthManager: Dev token stored successfully")
            }
        } catch {
            print("DEBUG AuthManager: Error fetching dev token: \(error)")
            print("DEBUG AuthManager: Error type: \(type(of: error))")
            DispatchQueue.main.async {
                self.authError = error.localizedDescription
                self.isAuthenticating = false
            }
        }
    }

    // MARK: - Spotify

    func setSpotifyAccessToken(_ token: String) {
        storageManager?.spotifyAccessToken = token
    }

    func clearSpotifyAuth() {
        storageManager?.spotifyAccessToken = nil
    }
}

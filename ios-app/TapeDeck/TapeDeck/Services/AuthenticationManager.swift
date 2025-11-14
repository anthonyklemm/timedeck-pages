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

    // MARK: - Create Apple Music Playlist (Using Native MusicKit)

    func createAppleMusicPlaylist(name: String, tracks: [Track]) async -> (success: Bool, message: String) {
        print("DEBUG AuthManager: createAppleMusicPlaylist called with \(tracks.count) tracks")

        // First, ensure we have authorization
        let authorized = await requestMusicKitAuthorization()
        guard authorized else {
            print("DEBUG AuthManager: User denied MusicKit authorization")
            return (false, "Apple Music access denied. Please enable in Settings.")
        }

        print("DEBUG AuthManager: User authorized, searching for tracks in Apple Music catalog")

        do {
            // First, search for all tracks in the catalog to get Song objects
            var catalogSongs: [Song] = []
            var notFoundTracks: [String] = []

            for track in tracks {
                do {
                    let searchTerm = "\(track.artist) \(track.title)"
                    print("DEBUG AuthManager: Searching for '\(track.title)' by '\(track.artist)'")

                    var request = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
                    request.limit = 1

                    let results = try await request.response()

                    if let firstSong = results.songs.first {
                        catalogSongs.append(firstSong)
                        print("DEBUG AuthManager: Found track: \(firstSong.title)")
                    } else {
                        notFoundTracks.append("\(track.title) by \(track.artist)")
                        print("DEBUG AuthManager: Could not find track: \(track.title)")
                    }
                } catch {
                    print("DEBUG AuthManager: Error searching for track: \(error)")
                    notFoundTracks.append("\(track.title) by \(track.artist)")
                }
            }

            print("DEBUG AuthManager: Found \(catalogSongs.count)/\(tracks.count) tracks in Apple Music")

            guard !catalogSongs.isEmpty else {
                return (false, "Could not find any tracks in Apple Music catalog.")
            }

            // Create the playlist
            print("DEBUG AuthManager: Creating playlist: \(name)")
            let playlist = try await MusicLibrary.shared.createPlaylist(
                name: name,
                description: "Created by TapeDeck Time Machine"
            )

            // Add each song to the playlist
            var addedCount = 0
            for song in catalogSongs {
                do {
                    _ = try await MusicLibrary.shared.add(song, to: playlist)
                    addedCount += 1
                    print("DEBUG AuthManager: Added '\(song.title)' to playlist")
                } catch {
                    print("DEBUG AuthManager: Error adding song to playlist: \(error)")
                }
            }

            print("DEBUG AuthManager: Successfully added \(addedCount) tracks to playlist")

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

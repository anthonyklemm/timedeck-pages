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

    // MARK: - Create Apple Music Playlist (Using MusicKit)

    func createAppleMusicPlaylist(name: String, tracks: [Track]) async -> (success: Bool, message: String) {
        print("DEBUG AuthManager: createAppleMusicPlaylist called with \(tracks.count) tracks")

        // First, ensure we have authorization
        let authorized = await requestMusicKitAuthorization()
        guard authorized else {
            print("DEBUG AuthManager: User denied MusicKit authorization")
            return (false, "Apple Music access denied. Please enable in Settings.")
        }

        print("DEBUG AuthManager: User authorized, searching for tracks")

        do {
            // Search for each track in the Apple Music catalog
            var catalogTracks: [MusicKit.Track] = []

            for track in tracks {
                do {
                    // Search for the track in Apple Music catalog
                    var request = MusicCatalogSearchRequest(term: "\(track.artist) \(track.title)")
                    request.limit = 1

                    let results = try await request.response()

                    if let firstTrack = results.tracks.first {
                        catalogTracks.append(firstTrack)
                        print("DEBUG AuthManager: Found track: \(track.title)")
                    } else {
                        print("DEBUG AuthManager: Could not find track: \(track.title)")
                    }
                } catch {
                    print("DEBUG AuthManager: Error searching for track \(track.title): \(error)")
                    // Continue searching for other tracks even if one fails
                }
            }

            guard !catalogTracks.isEmpty else {
                print("DEBUG AuthManager: No tracks found in Apple Music catalog")
                return (false, "Could not find any of these tracks in Apple Music.")
            }

            print("DEBUG AuthManager: Found \(catalogTracks.count) tracks, creating playlist")

            // Create the playlist using LibraryChangeRequest
            var changeRequest = LibraryPlaylistChangeRequest(name: name)
            changeRequest.tracks = catalogTracks
            let playlist = try await changeRequest.response()

            print("DEBUG AuthManager: Playlist created successfully: \(playlist.name)")
            return (true, "Playlist '\(playlist.name)' created successfully with \(catalogTracks.count) tracks!")

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

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

        print("DEBUG AuthManager: User authorized, searching for tracks in Apple Music catalog")

        do {
            var foundTracks: [String] = []
            var notFoundTracks: [String] = []
            var simulatorError = false

            // Search for each track in the Apple Music catalog
            for (index, track) in tracks.enumerated() {
                do {
                    let searchTerm = "\(track.artist) \(track.title)"
                    print("DEBUG AuthManager: Searching for '\(track.title)' by '\(track.artist)'")

                    // Use MusicCatalogSearchRequest to find the track
                    var request = MusicCatalogSearchRequest(term: searchTerm, types: [MusicKit.Song.self])
                    request.limit = 1

                    let results = try await request.response()

                    if let firstSong = results.songs.first {
                        foundTracks.append("\(firstSong.title) by \(firstSong.artistName)")
                        print("DEBUG AuthManager: Found track: \(firstSong.title)")
                    } else {
                        notFoundTracks.append("\(track.title) by \(track.artist)")
                        print("DEBUG AuthManager: Could not find track: \(track.title)")
                    }
                } catch {
                    let errorStr = error.localizedDescription
                    if errorStr.contains("developerTokenRequestFailed") || errorStr.contains("Ventura") {
                        simulatorError = true
                        print("DEBUG AuthManager: Simulator limitation detected")
                    }
                    notFoundTracks.append("\(track.title) by \(track.artist)")
                    print("DEBUG AuthManager: Error searching for track: \(error)")

                    // Stop searching on first error if it's a simulator limitation
                    if simulatorError && index > 0 {
                        break
                    }
                }
            }

            print("DEBUG AuthManager: Found \(foundTracks.count)/\(tracks.count) tracks in Apple Music")

            // Handle simulator limitation
            if simulatorError {
                var message = "🔧 Apple Music search requires a physical iPhone or Mac with macOS Ventura+.\n\n"
                message += "For now, you can manually add these tracks to a playlist:\n"
                message += "1. Open Apple Music app\n"
                message += "2. Create new playlist '\(name)'\n"
                message += "3. Search for and add these \(tracks.count) tracks"
                return (true, message)
            }

            // Return results if search worked
            if foundTracks.isEmpty && notFoundTracks.isEmpty {
                return (true, "Ready to create playlist! Add \(tracks.count) tracks to '\(name)' in Apple Music app.")
            }

            if foundTracks.isEmpty {
                return (false, "Could not find any of these tracks in Apple Music catalog.")
            }

            var message = "Found \(foundTracks.count) out of \(tracks.count) tracks in Apple Music.\n\n"
            message += "Note: On your device, you can add these tracks to a playlist manually:\n"
            message += "1. Open Apple Music app\n"
            message += "2. Create new playlist '\(name)'\n"
            message += "3. Add the found tracks to your playlist"

            if notFoundTracks.count > 0 {
                message += "\n\n⚠️ These tracks were not found:\n"
                message += notFoundTracks.prefix(5).joined(separator: "\n")
                if notFoundTracks.count > 5 {
                    message += "\n...and \(notFoundTracks.count - 5) more"
                }
            }

            return (true, message)

        } catch {
            print("DEBUG AuthManager: Error searching for tracks: \(error)")
            return (false, "Error searching Apple Music catalog: \(error.localizedDescription)")
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

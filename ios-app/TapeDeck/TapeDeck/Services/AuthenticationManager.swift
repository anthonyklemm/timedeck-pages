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

    // MARK: - Create Apple Music Playlist (Using Backend API)

    func createAppleMusicPlaylist(name: String, tracks: [Track]) async -> (success: Bool, message: String) {
        print("DEBUG AuthManager: createAppleMusicPlaylist called with \(tracks.count) tracks")

        // First, ensure we have authorization
        let authorized = await requestMusicKitAuthorization()
        guard authorized else {
            print("DEBUG AuthManager: User denied MusicKit authorization")
            return (false, "Apple Music access denied. Please enable in Settings.")
        }

        // Get the user token from MusicKit
        guard let userToken = try? await MusicAuthorization.musicUserToken() else {
            print("DEBUG AuthManager: Could not get Apple Music user token")
            return (false, "Could not get Apple Music user token. Please try again.")
        }

        print("DEBUG AuthManager: Got Apple Music user token, calling backend to create playlist")

        // Call the backend to create the playlist
        do {
            let response = try await apiClient.createAppleMusicPlaylist(
                userToken: userToken.rawValue,
                name: name,
                tracks: tracks
            )

            print("DEBUG AuthManager: Playlist created successfully")
            let message = "Successfully created playlist '\(name)' with \(tracks.count) tracks in Apple Music!"
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

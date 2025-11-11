import Foundation
import MusicKit

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var appleMusicAuthorized = false
    @Published var appleMusicUserToken: String?
    @Published var appleMusicDevToken: String?
    @Published var appleMusicStorefront: String?

    @Published var isAuthenticating = false
    @Published var authError: String?

    private weak var storageManager: StorageManager?
    private let apiClient = APIClient.shared

    override init() {
        super.init()
        loadSavedTokens()
        checkMusicKitAuthorization()
    }

    func setStorageManager(_ manager: StorageManager) {
        self.storageManager = manager
    }

    // MARK: - Apple Music MusicKit

    func checkMusicKitAuthorization() {
        Task {
            let status = await MusicAuthorization.request()
            DispatchQueue.main.async {
                self.appleMusicAuthorized = status == .authorized
            }
        }
    }

    func requestMusicKitAuthorization() async -> Bool {
        let status = await MusicAuthorization.request()
        DispatchQueue.main.async {
            self.appleMusicAuthorized = status == .authorized
        }
        return status == .authorized
    }

    func fetchAppleMusicDevToken() async {
        isAuthenticating = true
        authError = nil

        do {
            let response = try await apiClient.getAppleMusicDevToken()
            DispatchQueue.main.async {
                self.appleMusicDevToken = response.token
                self.appleMusicStorefront = response.storefront
                self.isAuthenticating = false
            }
        } catch {
            DispatchQueue.main.async {
                self.authError = error.localizedDescription
                self.isAuthenticating = false
            }
        }
    }

    func setAppleMusicUserToken(_ token: String) {
        self.appleMusicUserToken = token
        storageManager?.appleMusicUserToken = token
    }

    func clearAppleMusicAuth() {
        appleMusicUserToken = nil
        appleMusicDevToken = nil
        appleMusicStorefront = nil
        storageManager?.appleMusicUserToken = nil
    }

    // MARK: - Spotify

    func setSpotifyAccessToken(_ token: String) {
        storageManager?.spotifyAccessToken = token
    }

    func clearSpotifyAuth() {
        storageManager?.spotifyAccessToken = nil
    }

    // MARK: - Private

    private func loadSavedTokens() {
        if let token = storageManager?.appleMusicUserToken {
            appleMusicUserToken = token
        }
    }
}

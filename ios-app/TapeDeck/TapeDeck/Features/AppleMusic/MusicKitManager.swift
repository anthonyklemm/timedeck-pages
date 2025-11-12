import Foundation
import MusicKit

@MainActor
class MusicKitManager: ObservableObject {
    @Published var isInitialized = false
    @Published var errorMessage: String?

    private let applicationMusicPlayer = ApplicationMusicPlayer.shared

    init() {
        setupMusicPlayer()
    }

    // MARK: - Setup

    private func setupMusicPlayer() {
        Task {
            do {
                // Verify music player is available
                _ = applicationMusicPlayer
                isInitialized = true
            } catch {
                errorMessage = "Failed to initialize music player: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Playback Control

    func play() async {
        do {
            try await applicationMusicPlayer.play()
        } catch {
            errorMessage = "Failed to play: \(error.localizedDescription)"
        }
    }

    func pause() async {
        do {
            try await applicationMusicPlayer.pause()
        } catch {
            errorMessage = "Failed to pause: \(error.localizedDescription)"
        }
    }

    func skipToNextItem() async {
        do {
            try await applicationMusicPlayer.skipToNextEntry()
        } catch {
            errorMessage = "Failed to skip: \(error.localizedDescription)"
        }
    }

    func skipToPreviousItem() async {
        do {
            try await applicationMusicPlayer.skipToPreviousEntry()
        } catch {
            errorMessage = "Failed to skip back: \(error.localizedDescription)"
        }
    }
}

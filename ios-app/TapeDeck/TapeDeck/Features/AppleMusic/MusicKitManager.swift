import Foundation
import MusicKit

@MainActor
class MusicKitManager: NSObject, ObservableObject {
    @Published var isInitialized = false
    @Published var developerToken: String?
    @Published var currentlyPlaying: Music.MediaItem?
    @Published var isPlaying = false
    @Published var errorMessage: String?

    private var musicPlayer: ApplicationMusicPlayer?

    override init() {
        super.init()
        setupMusicPlayer()
    }

    // MARK: - Setup

    private func setupMusicPlayer() {
        Task {
            do {
                musicPlayer = ApplicationMusicPlayer.shared
                isInitialized = true
            } catch {
                errorMessage = "Failed to initialize music player: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Playback Control

    func play() async {
        do {
            try await musicPlayer?.play()
            isPlaying = true
        } catch {
            errorMessage = "Failed to play: \(error.localizedDescription)"
        }
    }

    func pause() async {
        do {
            try await musicPlayer?.pause()
            isPlaying = false
        } catch {
            errorMessage = "Failed to pause: \(error.localizedDescription)"
        }
    }

    func skipToNextItem() async {
        do {
            try await musicPlayer?.skipToNextEntry()
        } catch {
            errorMessage = "Failed to skip: \(error.localizedDescription)"
        }
    }

    func skipToPreviousItem() async {
        do {
            try await musicPlayer?.skipToPreviousEntry()
        } catch {
            errorMessage = "Failed to skip back: \(error.localizedDescription)"
        }
    }

    // MARK: - Queue Management

    func setQueue(with items: [Music.MediaItem]) async {
        do {
            var queue = ApplicationMusicPlayer.Queue()
            queue = queue.appending(contentsOf: items)
            try await musicPlayer?.setQueue(queue)
        } catch {
            errorMessage = "Failed to set queue: \(error.localizedDescription)"
        }
    }

    func clearQueue() async {
        do {
            var emptyQueue = ApplicationMusicPlayer.Queue()
            try await musicPlayer?.setQueue(emptyQueue)
        } catch {
            errorMessage = "Failed to clear queue: \(error.localizedDescription)"
        }
    }
}

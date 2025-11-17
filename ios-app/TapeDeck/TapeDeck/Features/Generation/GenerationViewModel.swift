import Foundation

@MainActor
class GenerationViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedDate = Date()
    @Published var selectedGenre = "Hot-100"
    @Published var selectedDuration: Double = 1.0
    @Published var repeatGapMin = 90
    @Published var currentTracks: [Track] = []
    @Published var youtubeVideoIds: [String] = []
    @Published var isLoading = false
    @Published var isCreatingPlaylist = false
    @Published var errorMessage: String?

    // MARK: - Constants

    static let GENRES = ["Hot-100", "Rock", "Hip-Hop", "R&B", "Pop", "Country", "Alternative"]
    static let DURATIONS: [Double] = [0.5, 1, 2, 3]

    // MARK: - Private Properties

    private let apiClient: APIClient
    private let storageManager: StorageManager
    private let analyticsManager: AnalyticsManager

    init(
        apiClient: APIClient,
        storageManager: StorageManager,
        analyticsManager: AnalyticsManager
    ) {
        self.apiClient = apiClient
        self.storageManager = storageManager
        self.analyticsManager = analyticsManager
    }

    // MARK: - Public Methods

    func generatePlaylist() async {
        isLoading = true
        errorMessage = nil

        analyticsManager.trackSearchInitiated()

        do {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            let dateString = dateFormatter.string(from: selectedDate)

            let durationInt = selectedDuration < 1 ? 0 : Int(selectedDuration)

            let tracks = try await apiClient.generatePlaylist(
                date: dateString,
                genre: selectedGenre,
                hours: durationInt > 0 ? durationInt : 1,
                repeatGapMin: repeatGapMin
            )

            currentTracks = tracks
            analyticsManager.trackSearchResults(count: tracks.count)

            // Automatically resolve YouTube videos after generating playlist
            await resolveYouTubeVideos(tracks: tracks)

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            analyticsManager.trackSearchZeroResults()
            isLoading = false
        }
    }

    func createAppleMusicPlaylist(userToken: String, name: String, tracks: [Track]) async {
        isLoading = true
        errorMessage = nil

        analyticsManager.trackExportAttempt(provider: "apple_music")

        do {
            let response = try await apiClient.createAppleMusicPlaylist(
                userToken: userToken,
                name: name,
                tracks: tracks
            )

            analyticsManager.trackExportSuccess(provider: "apple_music", count: response.addedCount)
            isLoading = false

            // Show success message
            errorMessage = nil
        } catch {
            analyticsManager.trackExportError(provider: "apple_music", error: error.localizedDescription)
            errorMessage = "Failed to create playlist: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func resolveYouTubeVideos(tracks: [Track]) async {
        analyticsManager.trackExportAttempt(provider: "youtube")

        do {
            let videoIds = try await apiClient.resolveYouTubeVideos(
                tracks: tracks,
                limit: tracks.count
            )

            self.youtubeVideoIds = videoIds
            analyticsManager.trackExportSuccess(provider: "youtube", count: videoIds.count)
        } catch {
            analyticsManager.trackExportError(provider: "youtube", error: error.localizedDescription)
            errorMessage = "Failed to resolve YouTube videos: \(error.localizedDescription)"
        }
    }
}

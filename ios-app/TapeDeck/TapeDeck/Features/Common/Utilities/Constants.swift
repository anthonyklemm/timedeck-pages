import Foundation

struct AppConstants {
    // MARK: - API Configuration

    static let apiBaseURL = "https://timedeck-api.onrender.com"
    static let networkTimeoutSeconds: TimeInterval = 180.0

    // MARK: - Music Configuration

    static let appleMusicGenres = [
        "Hot-100",
        "Rock",
        "Hip-Hop",
        "R&B",
        "Pop",
        "Country"
    ]

    static let playlistDurations: [Double] = [0.5, 1, 2, 3]
    static let defaultRepeatGapMinutes = 90
    static let minRepeatGapMinutes = 0
    static let maxRepeatGapMinutes = 180
    static let repeatGapStepSize: Double = 15

    // MARK: - UI Configuration

    static let cornerRadius: CGFloat = 12
    static let standardPadding: CGFloat = 16
    static let smallPadding: CGFloat = 8

    // MARK: - Storage Keys

    struct StorageKeys {
        static let anonUserId = "tdtm_uid_v1"
        static let sessionId = "tdtm_sid_v1"
        static let appleMusicUserToken = "appleMusicUserToken"
        static let spotifyAccessToken = "spotifyAccessToken"
        static let formState = "td_form"
        static let lastTracks = "td_lastTracks"
        static let analyticsOptOut = "analytics_opt_out"
    }

    // MARK: - Session Configuration

    static let sessionIdTTLMinutes = 30

    // MARK: - Analytics

    struct AnalyticsEvents {
        static let searchInitiated = "search_initiated"
        static let searchResults = "search_results"
        static let searchZeroResults = "search_zero_results"
        static let authStart = "auth_start"
        static let authSuccess = "auth_success"
        static let authError = "auth_error"
        static let exportAttempt = "export_attempt"
        static let exportSuccess = "export_success"
        static let exportError = "export_error"
    }

    // MARK: - Notifications

    enum NotificationName {
        static let playlistCreated = Notification.Name("playlistCreated")
        static let authStatusChanged = Notification.Name("authStatusChanged")
        static let networkError = Notification.Name("networkError")
    }
}

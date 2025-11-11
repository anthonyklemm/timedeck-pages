import Foundation

class AnalyticsManager: ObservableObject {
    private let apiClient = APIClient.shared
    private var storageManager: StorageManager?

    func setStorageManager(_ manager: StorageManager) {
        self.storageManager = manager
    }

    // MARK: - Event Tracking

    func trackEvent(
        _ eventName: String,
        properties: [String: AnyCodable]? = nil
    ) {
        guard let storageManager = storageManager,
              !storageManager.analyticsOptOut else {
            return
        }

        let event = AnalyticsEvent(
            event: eventName,
            ts: ISO8601DateFormatter().string(from: Date()),
            anonUserId: storageManager.anonUserId,
            sessionId: storageManager.sessionId,
            props: properties
        )

        Task {
            do {
                try await apiClient.submitAnalyticsEvent(event)
            } catch {
                // Silently fail analytics, don't disrupt user experience
                print("Analytics submission failed: \(error)")
            }
        }
    }

    // MARK: - Common Events

    func trackSearchInitiated() {
        trackEvent("search_initiated")
    }

    func trackSearchResults(count: Int) {
        trackEvent("search_results", properties: [
            "count": .int(count)
        ])
    }

    func trackSearchZeroResults() {
        trackEvent("search_zero_results")
    }

    func trackAuthStart(provider: String) {
        trackEvent("auth_start", properties: [
            "provider": .string(provider)
        ])
    }

    func trackAuthSuccess(provider: String) {
        trackEvent("auth_success", properties: [
            "provider": .string(provider)
        ])
    }

    func trackAuthError(provider: String, error: String) {
        trackEvent("auth_error", properties: [
            "provider": .string(provider),
            "error": .string(error)
        ])
    }

    func trackExportAttempt(provider: String) {
        trackEvent("export_attempt", properties: [
            "provider": .string(provider)
        ])
    }

    func trackExportSuccess(provider: String, count: Int) {
        trackEvent("export_success", properties: [
            "provider": .string(provider),
            "count": .int(count)
        ])
    }

    func trackExportError(provider: String, error: String) {
        trackEvent("export_error", properties: [
            "provider": .string(provider),
            "error": .string(error)
        ])
    }
}

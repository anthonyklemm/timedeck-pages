import SwiftUI
import MusicKit

@main
struct TapeDeckApp: App {
    @State private var apiClient = APIClient()
    @State private var authManager = AuthenticationManager()
    @State private var storageManager = StorageManager()
    @State private var analyticsManager = AnalyticsManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(apiClient)
                .environmentObject(authManager)
                .environmentObject(storageManager)
                .environmentObject(analyticsManager)
        }
    }
}

import SwiftUI
import MusicKit

@main
struct TapeDeckApp: App {
    @State private var apiClient = APIClient()
    @State private var authManager = AuthenticationManager()
    @State private var storageManager = StorageManager()
    @State private var analyticsManager = AnalyticsManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(apiClient)
                    .environmentObject(authManager)
                    .environmentObject(storageManager)
                    .environmentObject(analyticsManager)

                if showSplash {
                    SplashScreenView(onDismiss: {
                        showSplash = false
                    })
                }
            }
        }
    }
}

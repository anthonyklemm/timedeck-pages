import SwiftUI

struct ContentView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var analyticsManager: AnalyticsManager

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // YouTube Tab
            YouTubeView()
                .tabItem {
                    Label("YouTube", systemImage: "play.rectangle.fill")
                }
                .tag(0)

            // Apple Music Tab
            AppleMusicView()
                .tabItem {
                    Label("Apple Music", systemImage: "music.note")
                }
                .tag(1)

            // Spotify Tab (placeholder for phase 2)
            SpotifyPlaceholderView()
                .tabItem {
                    Label("Spotify", systemImage: "music.note.list")
                }
                .tag(2)
        }
        .onAppear {
            setupManagers()
        }
    }

    private func setupManagers() {
        authManager.setStorageManager(storageManager)
        analyticsManager.setStorageManager(storageManager)
    }
}

// MARK: - Placeholder Views

struct YouTubeView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var analyticsManager: AnalyticsManager

    var body: some View {
        NavigationStack {
            VStack {
                GenerationView(
                    apiClient: apiClient,
                    storageManager: storageManager,
                    analyticsManager: analyticsManager,
                    provider: "youtube"
                )
                .navigationTitle("YouTube")
            }
        }
    }
}

struct AppleMusicView: View {
    @EnvironmentObject var apiClient: APIClient
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var analyticsManager: AnalyticsManager

    var body: some View {
        NavigationStack {
            VStack {
                if authManager.appleMusicAuthorized {
                    GenerationView(
                        apiClient: apiClient,
                        storageManager: storageManager,
                        analyticsManager: analyticsManager,
                        provider: "apple"
                    )
                    .navigationTitle("Apple Music")
                } else {
                    AppleMusicAuthView()
                        .navigationTitle("Apple Music")
                }
            }
        }
    }
}

struct AppleMusicAuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In to Apple Music")
                .font(.title)

            Text("Get access to create playlists and listen to your generated time machine sessions.")
                .font(.body)
                .foregroundColor(.gray)

            Button(action: {
                Task {
                    _ = await authManager.requestMusicKitAuthorization()
                }
            }) {
                Label("Sign In with Apple Music", systemImage: "music.note")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()
        }
        .padding()
    }
}

struct SpotifyPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Spotify Coming Soon")
                .font(.title)

            Text("Spotify integration will be available in a future update. Follow along as we expand TapeDeck to more platforms!")
                .font(.body)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(APIClient())
        .environmentObject(AuthenticationManager())
        .environmentObject(StorageManager())
        .environmentObject(AnalyticsManager())
}

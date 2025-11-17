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
                        .foregroundColor(.tdTextPrimary)
                }
                .tag(0)

            // Apple Music Tab
            AppleMusicView()
                .tabItem {
                    Label("Apple Music", systemImage: "music.note")
                        .foregroundColor(.tdTextPrimary)
                }
                .tag(1)

            // Spotify Tab (placeholder for phase 2)
            SpotifyPlaceholderView()
                .tabItem {
                    Label("Spotify", systemImage: "music.note.list")
                        .foregroundColor(.tdTextPrimary)
                }
                .tag(2)
        }
        .tint(.tdCyan)
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
                .navigationTitle("TapeDeck - YouTube")
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
                    .navigationTitle("TapeDeck - Apple Music")
                } else {
                    AppleMusicAuthView()
                        .navigationTitle("TapeDeck - Apple Music")
                }
            }
        }
    }
}

struct AppleMusicAuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        ZStack {
            Color.tdBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Sign In to Apple Music")
                    .font(.title)
                    .foregroundColor(.tdTextPrimary)

                Text("Get access to create playlists and listen to your generated time machine sessions.")
                    .font(.body)
                    .foregroundColor(.tdTextSecondary)

                Button(action: {
                    Task {
                        _ = await authManager.requestMusicKitAuthorization()
                    }
                }) {
                    Label("Sign In with Apple Music", systemImage: "music.note")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.tdPurple, Color.tdCyan]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct SpotifyPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.tdBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Spotify Coming Soon")
                    .font(.title)
                    .foregroundColor(.tdTextPrimary)

                Text("Spotify integration will be available in a future update. Follow along as we expand TapeDeck to more platforms!")
                    .font(.body)
                    .foregroundColor(.tdTextSecondary)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(APIClient())
        .environmentObject(AuthenticationManager())
        .environmentObject(StorageManager())
        .environmentObject(AnalyticsManager())
}

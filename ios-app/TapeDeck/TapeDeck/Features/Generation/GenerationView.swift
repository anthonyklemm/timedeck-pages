import SwiftUI

struct GenerationView: View {
    @StateObject private var viewModel: GenerationViewModel
    @EnvironmentObject var authManager: AuthenticationManager

    let provider: String

    init(
        apiClient: APIClient,
        storageManager: StorageManager,
        analyticsManager: AnalyticsManager,
        provider: String
    ) {
        self.provider = provider
        _viewModel = StateObject(
            wrappedValue: GenerationViewModel(
                apiClient: apiClient,
                storageManager: storageManager,
                analyticsManager: analyticsManager
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Machine")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Select a date and genre to generate a playlist from that time period")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

                // Form Card
                VStack(spacing: 16) {
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Date", systemImage: "calendar")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        DatePicker(
                            "Select Date",
                            selection: $viewModel.selectedDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }

                    Divider()

                    // Genre Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Genre", systemImage: "guitars")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Picker("Genre", selection: $viewModel.selectedGenre) {
                            ForEach(GenerationViewModel.GENRES, id: \.self) { genre in
                                Text(genre).tag(genre)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Duration Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Duration", systemImage: "clock")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Picker("Duration", selection: $viewModel.selectedDuration) {
                            ForEach(GenerationViewModel.DURATIONS, id: \.self) { duration in
                                Text("\(duration) hour\(duration > 1 ? "s" : "")").tag(duration)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Divider()

                    // Repeat Gap
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Repeat Gap", systemImage: "timer")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Spacer()

                            Text("\(viewModel.repeatGapMin) min")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(viewModel.repeatGapMin) },
                                set: { viewModel.repeatGapMin = Int($0) }
                            ),
                            in: 0...180,
                            step: 15
                        )
                    }

                    // Generate Button
                    Button(action: { Task { await viewModel.generatePlaylist() } }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Label("Generate Playlist", systemImage: "sparkles")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(viewModel.isLoading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()

                // Error Message
                if let error = viewModel.errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)

                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemRed).opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }

                // Playlist Display
                if !viewModel.currentTracks.isEmpty {
                    PlaylistView(
                        tracks: viewModel.currentTracks,
                        provider: provider,
                        onCreatePlaylist: {
                            Task { await createPlaylist() }
                        }
                    )
                    .padding()
                }

                Spacer()
            }
        }
    }

    private func createPlaylist() async {
        let playlistName = "TapeDeckTimeMachine - \(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted)) - \(viewModel.selectedGenre)"

        switch provider {
        case "apple":
            await createAppleMusicPlaylist(name: playlistName)
        case "youtube":
            openYouTubePlaylist()
        default:
            break
        }
    }

    private func createAppleMusicPlaylist(name: String) async {
        guard let userToken = authManager.appleMusicUserToken else {
            await authManager.fetchAppleMusicDevToken()
            return
        }

        await viewModel.createAppleMusicPlaylist(
            userToken: userToken,
            name: name,
            tracks: viewModel.currentTracks
        )
    }

    private func openYouTubePlaylist() {
        Task {
            await viewModel.resolveYouTubeVideos(tracks: viewModel.currentTracks)

            // Open in YouTube app or Safari
            if let youtubeURL = URL(string: "https://www.youtube.com") {
                await UIApplication.shared.open(youtubeURL)
            }
        }
    }
}

// MARK: - Playlist View

struct PlaylistView: View {
    let tracks: [Track]
    let provider: String
    let onCreatePlaylist: () -> Void

    @State private var showingPlaylist = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Playlist")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(tracks.count) tracks")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Create Playlist Button
            Button(action: onCreatePlaylist) {
                Label(provider == "apple" ? "Create in Apple Music" : "Open in YouTube", systemImage: provider == "apple" ? "heart" : "play.circle")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Track List
            VStack(spacing: 8) {
                ForEach(tracks.prefix(10)) { track in
                    TrackRow(track: track)
                }

                if tracks.count > 10 {
                    Button(action: { showingPlaylist = true }) {
                        Text("View all \(tracks.count) tracks")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingPlaylist) {
                PlaylistFullView(tracks: tracks)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Helper Functions

func formatTimestamp(_ timestamp: String) -> String {
    // Timestamp format: "2002-07-01T00:00:00Z"
    // Extract time portion
    let components = timestamp.split(separator: "T")
    if components.count == 2 {
        let timePart = components[1]
        let timeOnly = timePart.split(separator: ":").prefix(2).joined(separator: ":")
        return timeOnly
    }
    return timestamp
}

struct TrackRow: View {
    let track: Track

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                Text(formatTimestamp(track.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Divider()
        }
    }
}

struct PlaylistFullView: View {
    let tracks: [Track]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(tracks) { track in
                        TrackRow(track: track)
                    }
                }
                .padding()
            }
            .navigationTitle("Full Playlist (\(tracks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    GenerationView(
        apiClient: APIClient(),
        storageManager: StorageManager(),
        analyticsManager: AnalyticsManager(),
        provider: "apple"
    )
    .environmentObject(AuthenticationManager())
}

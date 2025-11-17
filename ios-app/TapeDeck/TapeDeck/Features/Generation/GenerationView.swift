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
        ZStack {
            Color.tdBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Machine")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.tdTextPrimary)

                        Text("Select a date and genre to generate a playlist from that time period")
                            .font(.caption)
                            .foregroundColor(.tdTextSecondary)
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
                                .foregroundColor(.tdTextPrimary)

                            DatePicker(
                                "Select Date",
                                selection: $viewModel.selectedDate,
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .tint(.tdCyan)
                            .foregroundColor(.tdTextPrimary)
                            .colorScheme(.dark)
                        }

                        Divider().background(Color.tdTextSecondary.opacity(0.2))

                        // Genre Dropdown
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Genre", systemImage: "guitars")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.tdTextPrimary)

                            Menu {
                                ForEach(GenerationViewModel.GENRES, id: \.self) { genre in
                                    Button(genre) {
                                        viewModel.selectedGenre = genre
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedGenre)
                                        .foregroundColor(.tdTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.tdCyan)
                                }
                                .padding()
                                .background(Color.tdBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.tdPurple.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }

                        Divider().background(Color.tdTextSecondary.opacity(0.2))

                        // Duration Dropdown
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Duration", systemImage: "clock")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.tdTextPrimary)

                            Menu {
                                ForEach(GenerationViewModel.DURATIONS, id: \.self) { duration in
                                    Button(duration.formatDuration() + " hour\(duration > 1 ? "s" : "")") {
                                        viewModel.selectedDuration = duration
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(viewModel.selectedDuration.formatDuration() + " hour\(viewModel.selectedDuration > 1 ? "s" : "")")
                                        .foregroundColor(.tdTextPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.tdCyan)
                                }
                                .padding()
                                .background(Color.tdBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.tdPurple.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }

                        Divider().background(Color.tdTextSecondary.opacity(0.2))

                        // Repeat Gap
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("Repeat Gap", systemImage: "timer")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.tdTextPrimary)

                                Spacer()

                                Text("\(viewModel.repeatGapMin) min")
                                    .font(.caption)
                                    .foregroundColor(.tdCyan)
                            }

                            Slider(
                                value: Binding(
                                    get: { Double(viewModel.repeatGapMin) },
                                    set: { viewModel.repeatGapMin = Int($0) }
                                ),
                                in: 0...180,
                                step: 15
                            )
                            .tint(.tdPurple)
                        }

                        // Generate Button
                        Button(action: { Task { await viewModel.generatePlaylist() } }) {
                            if viewModel.isLoading {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Generating...")
                                }
                            } else {
                                Label("Generate Playlist", systemImage: "sparkles")
                            }
                        }
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
                        .disabled(viewModel.isLoading)
                    }
                    .padding()
                    .background(Color.tdCard)
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
                        .environmentObject(viewModel)
                        .padding()
                    }

                    Spacer()
                }
            }
        }
    }

    private func createPlaylist() async {
        print("DEBUG: createPlaylist called for provider: \(provider)")
        let playlistName = "TapeDeckTimeMachine - \(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted)) - \(viewModel.selectedGenre)"

        switch provider {
        case "apple":
            print("DEBUG: Creating Apple Music playlist")
            await createAppleMusicPlaylist(name: playlistName)
        case "youtube":
            print("DEBUG: Opening YouTube playlist")
            openYouTubePlaylist()
        default:
            print("DEBUG: Unknown provider: \(provider)")
            break
        }
    }

    private func createAppleMusicPlaylist(name: String) async {
        print("DEBUG: createAppleMusicPlaylist called with name: \(name)")

        DispatchQueue.main.async {
            self.viewModel.isCreatingPlaylist = true
        }

        let (success, message) = await authManager.createAppleMusicPlaylist(
            name: name,
            tracks: viewModel.currentTracks
        )

        DispatchQueue.main.async {
            self.viewModel.isCreatingPlaylist = false
            if success {
                print("DEBUG: Playlist created successfully: \(message)")
                self.viewModel.errorMessage = message
            } else {
                print("DEBUG: Playlist creation failed: \(message)")
                self.viewModel.errorMessage = message
            }
        }
    }

    private func openYouTubePlaylist() {
        print("DEBUG: openYouTubePlaylist called")
        guard !viewModel.youtubeVideoIds.isEmpty else {
            print("DEBUG: No YouTube video IDs available")
            return
        }

        let playlistUrl = "https://www.youtube.com/watch_videos?video_ids=\(viewModel.youtubeVideoIds.joined(separator: ","))"
        print("DEBUG: Opening YouTube with URL: \(playlistUrl)")

        if let url = URL(string: playlistUrl) {
            Task {
                await UIApplication.shared.open(url)
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
    @State private var showShareSheet = false
    @EnvironmentObject var viewModel: GenerationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Generated Playlist")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.tdTextPrimary)

                Spacer()

                Text("\(tracks.count) tracks")
                    .font(.caption)
                    .foregroundColor(.tdTextSecondary)
            }

            // Buttons
            VStack(spacing: 8) {
                Button(action: onCreatePlaylist) {
                    if viewModel.isCreatingPlaylist {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                                .tint(.white)
                            Text(provider == "apple" ? "Creating Playlist..." : "Opening...")
                        }
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
                    } else {
                        Label(provider == "apple" ? "Save to Apple Music" : "Open in YouTube",
                              systemImage: provider == "apple" ? "heart.fill" : "play.circle")
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
                }
                .disabled(viewModel.isCreatingPlaylist)

                if provider == "youtube" {
                    Button(action: { showShareSheet = true }) {
                        Label("Share Playlist", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.tdCard)
                            .foregroundColor(.tdCyan)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.tdCyan.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .sheet(isPresented: $showShareSheet) {
                        let playlistUrl = "https://www.youtube.com/watch_videos?video_ids=\(viewModel.youtubeVideoIds.joined(separator: ","))"
                        let message = "Check out this TapeDeck Time Machine playlist! 🎵"
                        ShareSheet(items: [message, URL(string: playlistUrl) ?? ""])
                    }
                }
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
                            .foregroundColor(.tdCyan)
                    }
                }
            }
            .sheet(isPresented: $showingPlaylist) {
                PlaylistFullView(tracks: tracks)
            }
        }
        .padding()
        .background(Color.tdCard)
        .cornerRadius(12)
    }
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
                        .foregroundColor(.tdTextPrimary)
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.caption)
                        .foregroundColor(.tdTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(formatTimestamp(track.timestamp))
                    .font(.caption2)
                    .foregroundColor(.tdTextSecondary)
            }

            Divider().background(Color.tdTextSecondary.opacity(0.2))
        }
    }
}

struct PlaylistFullView: View {
    let tracks: [Track]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.tdBackground.ignoresSafeArea()

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
                            .foregroundColor(.tdCyan)
                    }
                }
            }
        }
    }
}

// MARK: - Helper Functions

func formatTimestamp(_ timestamp: String) -> String {
    let components = timestamp.split(separator: "T")
    if components.count == 2 {
        let timePart = components[1]
        let timeOnly = timePart.split(separator: ":").prefix(2).joined(separator: ":")
        return timeOnly
    }
    return timestamp
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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

# TapeDeck Time Machine - iOS App

A native SwiftUI iOS app for TapeDeck Time Machine that lets you generate playlists based on historical chart data.

## Architecture Overview

This is Phase 1 of the iOS app with Apple Music (MusicKit) support. The app uses:

- **SwiftUI** - Modern declarative UI framework
- **Combine** - Reactive programming with @Published, @ObservedObject, @StateObject
- **MusicKit v3** - Native Apple Music integration
- **URLSession** - Networking layer
- **Keychain** - Secure token storage

## Project Structure

```
TapeDeck/
├── App/
│   ├── TapeDeckApp.swift       # App entry point
│   └── ContentView.swift        # Root navigation
├── Features/
│   ├── Generation/             # Playlist generation
│   │   ├── GenerationView.swift
│   │   └── GenerationViewModel.swift
│   ├── AppleMusic/             # Apple Music features
│   │   └── MusicKitManager.swift
│   └── Common/                 # Shared components
├── Services/
│   ├── APIClient.swift         # Network requests
│   ├── AuthenticationManager.swift
│   ├── AnalyticsManager.swift
│   ├── StorageManager.swift
│   └── Models.swift            # Data models
└── Resources/                  # Images, strings, etc.
```

## Setup Instructions

### Prerequisites

- Xcode 15.0+
- iOS 17.0+ deployment target
- Apple Music subscription (for full testing)
- Apple Developer Account

### Step 1: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Choose "App" template under iOS
4. Fill in project details:
   - Product Name: `TapeDeck`
   - Team: Your Apple Developer Team
   - Organization Identifier: `com.tapedecktimemachine`
   - Bundle ID: `com.tapedecktimemachine.app`
   - Interface: SwiftUI
   - Life Cycle: SwiftUI App
5. Create the project

### Step 2: Add Source Files

1. Copy all Swift files from `TapeDeck/` to your Xcode project
2. Ensure all files are added to the build target

### Step 3: Configure Entitlements

1. In Xcode, select the project in the navigator
2. Select the "App" target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" and add:
   - **Music** (Apple Music access)
   - **Sign in with Apple** (for future auth)

### Step 4: Update Info.plist

Add to Info.plist:

```xml
<key>NSBonjourServices</key>
<array>
    <string>_musickit._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>TapeDeck needs access to find music on your network</string>
<key>NSBonjourServices</key>
<array>
    <string>_http._tcp</string>
    <string>_https._tcp</string>
</array>
```

### Step 5: Configure Apple Music Developer Token

1. Go to [Apple Music API](https://developer.apple.com/musickit/)
2. Create a MusicKit Identifier
3. Get your Developer Token
4. The app fetches it from `https://timedeck-api.onrender.com/v1/apple/dev-token`

### Step 6: Build and Run

```bash
# Build for simulator
xcodebuild -scheme TapeDeck -destination 'generic/platform=iOS Simulator' build

# Or use Xcode UI
# Select a target device/simulator and press Cmd+R
```

## Key Features Implemented in Phase 1

✅ **Playlist Generation**
- Date picker for selecting any date
- Genre selection (Hot-100, Rock, Hip-Hop, etc.)
- Duration control (0.5 to 3 hours)
- Repeat gap configuration

✅ **Apple Music Integration**
- MusicKit authorization flow
- User token management
- Playlist creation
- Basic playback controls

✅ **YouTube Integration**
- Video ID resolution
- Deep linking to YouTube app

✅ **Analytics**
- Event tracking (search, export, auth)
- Anonymous user IDs
- Session management
- Opt-out support

✅ **Data Storage**
- Secure Keychain storage for tokens
- UserDefaults for preferences
- UUID-based user tracking

## API Integration

The app communicates with `https://timedeck-api.onrender.com`:

### Core Endpoints

```
POST /v1/simulate
├─ Input: {date, genre, hours, repeat_gap_min, seed, limit}
└─ Output: {tracks: [Track]}

GET /v1/apple/dev-token
└─ Output: {token, storefront}

POST /v1/apple/create-playlist
├─ Input: {userToken, name, tracks}
└─ Output: {added_count, total_tracks}

POST /v1/yt/resolve
├─ Input: {tracks, limit}
└─ Output: {ids: [videoId]}

POST /v1/events
└─ Input: {v, event, ts, anon_user_id, session_id, props}
```

## Development Guidelines

### Adding New Features

1. Create new files in appropriate `Features/` subfolder
2. Follow MVVM pattern (View + ViewModel)
3. Add data models to `Models.swift`
4. Add API methods to `APIClient.swift`
5. Track relevant analytics events

### State Management

Use SwiftUI's built-in state management:
- `@State` for simple local state
- `@StateObject` for ViewModel instances
- `@EnvironmentObject` for app-wide services
- `@Published` in ObservableObject ViewModels

### Error Handling

All API errors should be caught and displayed:
1. Set `errorMessage` on ViewModel
2. Display in UI as a banner
3. Track with analytics

### Testing

Create preview providers for each view:

```swift
#Preview {
    YourView()
        .environmentObject(APIClient())
        .environmentObject(AuthenticationManager())
        // ... other dependencies
}
```

## Phase 2 & Beyond

**Spotify Integration**
- Add SpotifyView.swift
- Create SpotifyViewModel
- OAuth 2.0 authentication
- Playlist creation

**Advanced Features**
- Canvas-based visualizer
- Share functionality
- Offline support
- Push notifications

## Troubleshooting

### MusicKit Authorization Failed
- User must have iOS 17+
- User must have Apple ID signed in on device
- User must approve music access in Settings

### API Requests Timing Out
- Check network connectivity
- Verify API endpoint is accessible
- Check Xcode console for detailed errors

### Playlist Creation Fails
- Verify user token is valid
- Check Apple Music subscription status
- Ensure tracks are in Apple Music catalog

## Resources

- [MusicKit Documentation](https://developer.apple.com/musickit/)
- [SwiftUI Tutorial](https://developer.apple.com/tutorials/swiftui)
- [Apple Music API](https://developer.apple.com/documentation/applemusicapi)
- [URLSession Guide](https://developer.apple.com/documentation/foundation/urlsession)

## Notes

- This is a native iOS app, not a web wrapper
- All authentication uses native iOS frameworks
- No web popups or external browser needed
- Secure token storage in Keychain
- Background sync ready (future feature)

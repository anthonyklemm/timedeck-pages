# TapeDeck iOS App - Xcode 16 Setup Guide

Complete step-by-step setup instructions for **Xcode 16** (Version 16.0+)

---

## Step 1: Create a New Xcode 16 Project

### Create the Project

1. **Open Xcode → File → New → Project** (or Cmd+Shift+N)

2. **Select iOS App Template**
   - Make sure you're on the "iOS" tab
   - Select **"App"** template
   - Click "Next"

3. **Configure Project Options**
   - **Product Name:** `TapeDeck`
   - **Team:** Select your Apple Developer Team (or "None")
   - **Organization Identifier:** `com.tapedecktimemachine`
   - **Bundle ID:** Auto-fills as `com.tapedecktimemachine.app` ✓
   - **Interface:** **SwiftUI** (should be default)
   - **Life Cycle:** **SwiftUI App** (should be default)
   - **Language:** **Swift** (should be default)
   - **☐ Use Core Data** - Leave **UNCHECKED**
   - **☐ Include Tests** - Leave UNCHECKED for now
   - Click "Next"

4. **Choose Save Location**
   - Create in: `/home/user/timedeck-pages/ios-app-xcode/`
   - ✓ Create Git repository on My Mac (optional)
   - Click "Create"

---

## Step 2: Examine the Default Project Structure (Xcode 16)

Xcode 16 creates this structure:

```
TapeDeck/
├── TapeDeck/
│   ├── TapeDeckApp.swift          ← We'll replace this
│   ├── ContentView.swift          ← We'll replace this
│   ├── Preview Content/
│   │   └── Preview Assets.xcassets
│   └── Assets.xcassets
├── TapeDeckTests/                 ← We can ignore this
├── Info.plist                     ← We'll update this
└── TapeDeck.xcodeproj
```

---

## Step 3: Add Swift Source Files

### Step 3A: Prepare Your Files

Before you start, make sure you have all the Swift files ready:

```
/home/user/timedeck-pages/ios-app/TapeDeck/TapeDeck/
├── App/
│   ├── TapeDeckApp.swift
│   └── ContentView.swift
├── Features/
│   ├── Generation/
│   ├── AppleMusic/
│   ├── YouTube/
│   ├── Analytics/
│   └── Common/
└── Services/
```

### Step 3B: Add Folders to Xcode (Drag & Drop Method)

1. **Open Finder** alongside Xcode
   - Arrange windows side by side
   - Finder: Navigate to `/home/user/timedeck-pages/ios-app/TapeDeck/TapeDeck/`

2. **In Xcode Navigator** (left panel):
   - Click on the **"TapeDeck" folder** (the one with the app icon, not the project)
   - This is where you'll drag files

3. **Drag folders into Xcode:**
   - From Finder, drag **"App", "Features", "Services"** into the TapeDeck folder in Xcode
   - A dialog will appear with options:
     - ✓ **Copy items if needed** - CHECKED
     - ✓ **Create groups** - SELECTED (important!)
     - ✓ **Add to targets: TapeDeck** - CHECKED
   - Click "Finish"

4. **Wait for indexing** to complete (you'll see a progress indicator)

### Step 3C: Remove Default Files

1. **Right-click on auto-generated `ContentView.swift`** in Xcode navigator
   - Select **Delete**
   - Choose **"Remove Reference"** (don't delete the file)

2. **Right-click on auto-generated `TapeDeckApp.swift`**
   - Select **Delete**
   - Choose **"Remove Reference"**

The versions you dragged in will now be used instead. ✓

### Step 3D: Verify Files are Compiled

1. Select **TapeDeck project** → **TapeDeck target** → **Build Phases** tab
2. Expand **"Compile Sources"**
3. Verify ALL your `.swift` files are listed:
   - All files in Services/ (Models.swift, APIClient.swift, etc.)
   - All files in Features/
   - TapeDeckApp.swift and ContentView.swift from App/
4. If any are missing, click **"+"** and add them

---

## Step 4: Configure Project Settings (Xcode 16)

### Step 4A: Set Deployment Target

1. **Select the "TapeDeck" project** in navigator (top, blue icon)
2. **Select the "TapeDeck" target** in the editor area
3. Click the **"General" tab**
4. Look for **"Minimum Deployments"** section
   - **iOS:** Set to **17.0 or later** (MusicKit v3 requirement)
   - **macOS:** Leave as is
   - **tvOS:** Leave as is

### Step 4B: Verify Swift Language Settings

1. Stay in the **"TapeDeck" target** settings
2. Click the **"Build Settings" tab**
3. Use the search box at the top right to search:
   - Search: **"Swift Language Version"**
   - Should show **"Swift 5.9"** or later (usually automatic)

---

## Step 5: Add Capabilities (Xcode 16)

The UI for capabilities has changed slightly in Xcode 16:

### Step 5A: Add Music Capability

1. **Select TapeDeck project** → **TapeDeck target**
2. Click **"Signing & Capabilities"** tab
3. In the top right, you'll see a **"+ Capability"** button
4. Click it and search for **"Music"**
5. Select **"Music"** - it adds the capability automatically
6. You should now see a **"Music"** section appear

### Step 5B: Add Sign in with Apple (Optional)

1. Click **"+ Capability"** again
2. Search for **"Sign in with Apple"**
3. Click to add
4. You should see a new section for **"Sign in with Apple"**

---

## Step 6: Create Entitlements File (Xcode 16)

In Xcode 16, entitlements are often auto-generated, but let's make sure we have the MusicKit entitlement:

### Step 6A: Check if Entitlements Exist

1. Look in the **project navigator** for **"TapeDeck.entitlements"**
2. If it exists, skip to Step 6C
3. If it doesn't, continue to Step 6B

### Step 6B: Create the Entitlements File

1. **File → New → File** (Cmd+N)
2. Choose **"Property List"**
3. Name it **`TapeDeck.entitlements`**
4. Make sure it's added to the **TapeDeck target**
5. Click **"Create"**

### Step 6C: Edit the Entitlements File

1. **Click on `TapeDeck.entitlements`** in the navigator
2. In the editor, you should see a property list interface
3. Click the **"+"** button to add a new entry
4. **Key:** `com.apple.developer.music-kit`
5. **Type:** Change to **"Boolean"**
6. **Value:** ✓ (checked/true)

**OR** if you prefer editing as source code:
1. Right-click on `TapeDeck.entitlements`
2. Select **"Open as Source Code"**
3. Paste this:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.music-kit</key>
    <true/>
</dict>
</plist>
```

### Step 6D: Link Entitlements to Build Settings

1. **Select TapeDeck project → TapeDeck target**
2. Go to **"Build Settings"** tab
3. Search: **"Code Sign Entitlements"**
4. **Set the value to:** `TapeDeck/TapeDeck.entitlements`
   - (Or just `TapeDeck.entitlements` if it's in the root)

---

## Step 7: Update Info.plist (Xcode 16)

Xcode 16 handles Info.plist slightly differently. Here's how:

### Step 7A: Locate Info.plist

1. In the navigator, look for **"Info.plist"**
   - Usually it's in the root or under TapeDeck folder

### Step 7B: Edit Info.plist (Method 1 - Visual Editor)

1. **Click on Info.plist** to open it
2. Click the **"+"** button to add new keys
3. Add these THREE entries:

| Key | Type | Value |
|-----|------|-------|
| `NSBonjourServices` | Array | (empty array) |
| `NSLocalNetworkUsageDescription` | String | `TapeDeck needs access to find music on your network` |
| `NSMDNSAllowUnencryptedAccess` | Boolean | ✓ (true) |

4. For `NSBonjourServices` array, click the arrow to expand it
5. Click **"+"** inside it and add:
   - Type: **String**
   - Value: `_musickit._tcp`

### Step 7C: Edit Info.plist (Method 2 - Source Code)

If the visual editor is confusing:

1. **Right-click on Info.plist**
2. Select **"Open as Source Code"**
3. **Before the closing `</dict>`**, add:

```xml
<key>NSBonjourServices</key>
<array>
    <string>_musickit._tcp</string>
</array>
<key>NSLocalNetworkUsageDescription</key>
<string>TapeDeck needs access to find music on your network</string>
<key>NSMDNSAllowUnencryptedAccess</key>
<true/>
```

4. Save (Cmd+S)
5. Right-click again and select **"Open as Property List"** to switch back

---

## Step 8: Verify Build Configuration

Let's make sure everything is set up correctly:

### Checklist:

1. **Deployment Target**
   - [ ] TapeDeck target → General → Minimum Deployments set to iOS 17.0

2. **Swift Version**
   - [ ] Build Settings → Swift Language Version = 5.9 or later

3. **Capabilities**
   - [ ] Music capability added ✓
   - [ ] Sign in with Apple added ✓

4. **Entitlements**
   - [ ] TapeDeck.entitlements file exists
   - [ ] Contains `com.apple.developer.music-kit = true`
   - [ ] Build Settings → Code Sign Entitlements points to it

5. **Info.plist**
   - [ ] Has `NSBonjourServices` array with `_musickit._tcp`
   - [ ] Has `NSLocalNetworkUsageDescription` string
   - [ ] Has `NSMDNSAllowUnencryptedAccess = true`

6. **Source Files**
   - [ ] All .swift files in Compile Sources (Build Phases)
   - [ ] No duplicate TapeDeckApp.swift or ContentView.swift

---

## Step 9: Clean and Build

Before running, let's make sure everything builds:

1. **Product → Clean Build Folder** (Cmd+Shift+K)
   - This clears any cached build artifacts

2. **Product → Build** (Cmd+B)
   - Watch the build log at the bottom
   - You should see: **"Build complete!"**

### If you get errors:

**Error: "Cannot find module 'MusicKit'"**
- Go to Build Settings
- Search "Minimum Deployments"
- Make sure iOS is set to 17.0 or higher

**Error: "File not found: TapeDeck.entitlements"**
- Build Settings → Code Sign Entitlements
- Make sure the path is correct (should be `TapeDeck/TapeDeck.entitlements` or just `TapeDeck.entitlements`)

**Error: "Unexpected end of file"**
- Check Info.plist - make sure the XML is valid
- Count opening `<dict>` and closing `</dict>` tags

---

## Step 10: Run in Simulator

Once the build succeeds:

1. **Select a simulator** from the toolbar
   - Click the device selector at the top (next to "TapeDeck" scheme)
   - Choose **"iPhone 16 Pro"** or any recent iPhone
   - Click to select

2. **Run the app** (Cmd+R)
   - Xcode will build and launch the simulator
   - Wait for the app to appear

3. **You should see:**
   - ✓ Three tabs: YouTube, Apple Music, Spotify
   - ✓ YouTube tab shows generation form
   - ✓ Apple Music tab shows sign-in button
   - ✓ Spotify tab shows "Coming Soon"

**If you see this, you've successfully set up Xcode 16!** 🎉

---

## Xcode 16 Specific Notes

### Key Differences from Earlier Versions:

1. **Info.plist Editing**
   - Xcode 16 can edit as visual editor OR source code
   - You can switch between modes by right-clicking
   - No more separate plist file location

2. **Build Phases**
   - Same location, but the UI is slightly updated
   - Make sure all files are in "Compile Sources"

3. **Capabilities UI**
   - Slightly redesigned in Xcode 16
   - Click "+" button and search for capabilities
   - They auto-add to entitlements

4. **Swift Language Version**
   - Usually automatic in Xcode 16
   - Swift 5.9+ is standard

---

## Troubleshooting for Xcode 16

| Issue | Solution |
|-------|----------|
| "Code Sign Entitlements not found" | Build Settings → Code Sign Entitlements → Verify path is correct |
| "Missing MusicKit" | Build Settings → iOS Minimum Deployments must be 17.0+ |
| "Duplicate symbol" errors | Build Phases → Compile Sources → Remove duplicate files |
| App crashes on launch | Check Console output (View → Debug Area → Show Debug Area, or Cmd+Shift+Y) |
| "Swift 5.x is not available" | Update Xcode to latest version (currently 16.1+) |
| Simulator won't launch | Product → Clean Build Folder, then try again |

---

## Quick Checklist - Final

Before proceeding to testing:

- [ ] Xcode 16 project created
- [ ] All .swift files added to project
- [ ] iOS deployment target = 17.0
- [ ] Build Settings → Code Sign Entitlements path is correct
- [ ] Entitlements file created with MusicKit
- [ ] Info.plist updated with three new keys
- [ ] Project builds successfully (Cmd+B)
- [ ] App runs in simulator (Cmd+R)
- [ ] Three tabs visible in running app

---

## Next Steps

Once you have the app running in the simulator, we can:
1. Test the playlist generation feature
2. Verify API connectivity
3. Test Apple Music authentication
4. Review any console errors

Good luck! Let me know if you hit any Xcode 16 specific issues! 🚀

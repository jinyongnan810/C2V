# C2V - macOS Menu Bar Clipboard Manager

**C2V** is a lightweight, modern macOS status bar application that automatically intercepts, organizes, and manages your copied text snippets.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SwiftData-purple)

---

## Key Features

- 📋 **Menu Bar Interface**: Lives in the macOS status bar (`doc.on.clipboard` icon) with no Dock clutter (`LSUIElement`).
- ⚡ **Text Interception**: Automatically stores copied text snippets while ignoring file paths, binary files, and image objects.
- 🔍 **Real-Time Search & Filter**: Search through past clipboard entries instantly or filter pinned items.
- 📌 **Pin & Organize**: Pin your favorite code snippets or frequently used text to the top of the list.
- 🎯 **One-Tap Re-Copy**: Click any history item to re-copy it to your clipboard with visual "Copied!" feedback.
- 🚀 **Auto Start on Boot**: Built-in Launch at Login support using macOS `ServiceManagement` (`SMAppService`).

---

## Project Structure

```text
C2V/
├── C2V/
│   ├── C2VApp.swift                # App entry point with MenuBarExtra scene
│   ├── ContentView.swift           # Main popover UI with search, list, & settings
│   ├── CopiedItem.swift            # SwiftData model for stored snippets
│   ├── ClipboardMonitor.swift      # Real-time NSPasteboard monitor service
│   └── LaunchAtLoginManager.swift  # Auto-start helper using SMAppService
├── C2VTests/                       # Unit tests suite
├── C2VUITests/                     # UI tests suite
├── Makefile                        # Linting helper (make lint)
├── AGENTS.md                       # Guidelines for AI coding agents
├── PRIVACY_POLICY.md               # Privacy policy (local-only data statement)
└── README.md                       # Project documentation
```

---

## Requirements & Building

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0+ with Swift 6

### Building from Xcode
1. Open `C2V.xcodeproj` in Xcode.
2. Select target `C2V` and destination `My Mac`.
3. Press `Cmd + R` to run.

---

## Code Formatting

To check and format Swift files, run:

```bash
make lint
```

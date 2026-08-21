# C2V - macOS Menu Bar Clipboard Manager

**C2V** is a lightweight, modern, and privacy-focused macOS status bar application that automatically intercepts, organizes, and manages your copied text snippets. Built with SwiftUI, SwiftData, ServiceManagement, and Apple's Liquid Glass visual language.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-SwiftData-purple)
![Localization](https://img.shields.io/badge/Languages-English%20%7C%20Japanese-green)

---

## 🌟 Key Features

- 📋 **Menu Bar Integration**: Lives in the macOS status bar (`TrayIcon`) with zero Dock clutter (`LSUIElement = true`).
- 🖱️ **Right-Click Context Menu**: Right-click or `Ctrl+Click` the status bar icon to open a native menu with **Settings** (`Cmd+,`) and **Quit C2V** (`Cmd+Q`).
- ⚡ **Smart Text Interception**: Automatically records copied text snippets via background pasteboard monitoring. Intelligently filters out file paths (`.fileURL`) and images/binary files, ignores consecutive duplicates, and caps storage at 100 unpinned items. Re-copying an item updates its timestamp and moves it to the top.
- 🔍 **Real-Time Search & Filtering**: Instant case-insensitive text search with a quick clear action, plus a pin filter toggle to switch between all items and pinned snippets.
- 📌 **Pin & Organize**: Pin frequently used code snippets or important text snippets to keep them permanently at the top of your clipboard history.
- 👁️ **Quick Look Inspector**: Pop up an inspector modal with monospaced text preview, character, word, and line count statistics, relative date timestamp, and quick action buttons.
- 🎨 **Liquid Glass UI Styling**: Adopts macOS 26+ Liquid Glass visual effects (`liquidGlassEffect`) with graceful material fallbacks (`.ultraThinMaterial` / `.regularMaterial`) on earlier macOS versions.
- 🗑️ **Selective History Clearing**: Custom confirmation dialog to clear unpinned items while keeping pinned favorites, or clear everything at once.
- ⬆️ **Scroll to Top**: Floating action button automatically appears when scrolling down for quick return to the top of your list.
- 🚀 **Auto Start on Boot**: Toggle auto-launch at login powered natively by Apple's `ServiceManagement` framework (`SMAppService`).
- 🔒 **100% Local & Private**: All clipboard history is stored strictly on your local device using `SwiftData`. Zero telemetry, zero tracking, zero external network requests.
- 🌐 **Multilingual Support**: Fully localized in **English** and **Japanese** using Apple's String Catalog (`Localizable.xcstrings`).

---

## 📁 Project Structure

```text
C2V/
├── C2V/
│   ├── C2VApp.swift                            # Main app entry point & MenuBarExtra scene configuration
│   ├── ContentView.swift                       # Core popover UI, state management, search, & overlays
│   ├── Localizable.xcstrings                   # English & Japanese String Catalog localization
│   ├── Components/
│   │   ├── ClearConfirmationOverlay.swift      # History deletion confirmation dialog (unpinned vs all)
│   │   ├── CopiedItemRow.swift                 # Hoverable snippet row with action buttons (Quick Look, Pin, Delete)
│   │   ├── FadedItemText.swift                 # Multi-line text view with linear gradient fade mask
│   │   ├── LiquidGlassStyle.swift              # macOS 26+ Liquid Glass effect & backward compatibility fallbacks
│   │   ├── MenuBarExtraRightClickMonitor.swift # NSEvent listener for status bar item right-click context menu
│   │   ├── QuickLookOverlay.swift              # Text inspector modal with word/line/char stats and actions
│   │   ├── ScrollToTopButton.swift             # Floating action button for quick top scrolling
│   │   └── SettingsView.swift                  # Form view for launch-at-login, storage info, & privacy links
│   ├── Logics/
│   │   ├── ClipboardMonitor.swift              # Real-time pasteboard polling, deduplication, & SwiftData sync
│   │   └── LaunchAtLoginManager.swift          # Auto-start helper utilizing ServiceManagement (SMAppService)
│   └── Models/
│       └── CopiedItem.swift                    # SwiftData persistent model schema
├── C2VTests/                                   # Unit test suite
├── C2VUITests/                                 # UI test suite
├── Makefile                                    # SwiftFormat linting script (make lint)
├── AGENTS.md                                   # AI coding agent guidelines & rules
├── PRIVACY_POLICY.md                           # Comprehensive privacy policy document (English)
├── PRIVACY_POLICY_JA.md                        # Comprehensive privacy policy document (Japanese)
└── README.md                                   # Project documentation
```

---

## 🛠️ Tech Stack & Architecture

- **Language**: Swift 5
- **UI Framework**: SwiftUI (macOS 13.0+)
- **Menu Bar Engine**: `MenuBarExtra` (`.window` style) with custom `NSEvent` status bar monitoring
- **Data Persistence**: SwiftData (`@Model`, `ModelContainer`, `FetchDescriptor`, `#Predicate`)
- **System Integration**: `ServiceManagement` (`SMAppService.mainApp`) for Launch at Login
- **Design System**: Liquid Glass aesthetics with `.glass` / `.glassProminent` button styles and material fallbacks
- **Localization**: String Catalog (`.xcstrings`)

---

## 💻 Requirements & Building

### Prerequisites
- macOS 13.0 (Ventura) or later
- Xcode 15.0+ with Swift 5 support

### Building & Running
1. Clone the repository:
   ```bash
   git clone https://github.com/jinyongnan810/C2V.git
   cd C2V
   ```
2. Open `C2V.xcodeproj` in Xcode.
3. Select the `C2V` target and destination `My Mac`.
4. Press `Cmd + R` to build and run the application.

---

## 🎨 Code Formatting & Quality

Code formatting is enforced using SwiftFormat. To lint and format all Swift files in the repository, run:

```bash
make lint
```

---

## 🛡️ Privacy Policy

C2V is committed to user privacy. All copied text history remains 100% local on your Mac. For complete details, see our [Privacy Policy (English)](PRIVACY_POLICY.md) or [プライバシーポリシー (日本語)](PRIVACY_POLICY_JA.md).

---

## 📄 License

This project is open-source. Refer to the repository for licensing terms.

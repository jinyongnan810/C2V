# Agent Guidelines for C2V

This repository contains **C2V**, a lightweight, modern macOS menu bar application built with SwiftUI, SwiftData, and ServiceManagement.

## Mandatory Workflow Rules

> [!IMPORTANT]
> **Code Formatting & Linting Requirement**:
> After you finish updating or editing any Swift code files in this repository, you **MUST** run the following command to format and lint the code:
> ```bash
> make lint
> ```

## Project Architecture & Tech Stack

- **Platform**: macOS 13.0+ (SwiftUI, Swift 5)
- **Menu Bar Integration**: `MenuBarExtra` scene using `.window` style in `C2VApp.swift`.
- **Agent Mode (`Info.plist`)**: Configured with `LSUIElement = true` so the app runs strictly as a status bar item without taking up space in the macOS Dock.
- **Data Persistence**: `SwiftData` model (`CopiedItem`) storing `id`, `text`, `createdAt`, and `isPinned`.
- **Clipboard Interceptor**: `ClipboardMonitor` (ObservableObject polling `NSPasteboard.general`). Filters strictly for plain text, ignores file URLs/images, avoids duplicate entries, and caps storage at 100 items.
- **Launch at Login**: `LaunchAtLoginManager` using `ServiceManagement` framework (`SMAppService.mainApp`).

## Development & Xcode MCP Guidelines

- **Xcode Tooling**: Always use Xcode MCP tools (`BuildProject`, `RunAllTests`, `AddInfoPlist`, `XcodeRM`, etc.) for building, testing, and project configuration.
- **UI Design**: Ensure popover rows remain layout-stable when hovered (`.opacity(isHovered ? 1 : 0)` with `.allowsHitTesting(isHovered)`).

## Verification Steps
Before completing any task:
1. Run `make lint` to format all Swift code.
2. Build the project using Xcode MCP (`BuildProject`).
3. Do Not Run test suites unless told to. 
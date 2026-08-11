//
//  C2VApp.swift
//  C2V
//

import SwiftData
import SwiftUI

/// Main application entry point managing the status bar scene and SwiftData container.
@main
struct C2VApp: App {
    @State private var monitor = ClipboardMonitor()

    /// Initializes the application and starts monitoring right-click status bar events.
    init() {
        MenuBarExtraRightClickMonitor.shared.startMonitoring()
    }

    /// Persistent SwiftData model container storing clipboard history items.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CopiedItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// The main scene hierarchy comprising the status bar extra popover and app settings window.
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(monitor)
                .modelContainer(sharedModelContainer)
        } label: {
            Image("TrayIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .background(OpenSettingsBridgeView())
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

/// Bridge view connecting the status bar right-click menu callback to the SwiftUI settings environment.
private struct OpenSettingsBridgeView: View {
    @Environment(\.openSettings) private var openSettings

    /// Renders an invisible view that registers the open settings callback on appear.
    var body: some View {
        Color.clear
            .onAppear {
                MenuBarExtraRightClickMonitor.shared.onOpenSettings = {
                    NSApp.activate(ignoringOtherApps: true)
                    if #available(macOS 14.0, *) {
                        openSettings()
                    } else {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }
                }
            }
    }
}

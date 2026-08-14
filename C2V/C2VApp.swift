//
//  C2VApp.swift
//  C2V
//

import SwiftData
import SwiftUI

/// Main application entry point managing the status bar scene and SwiftData container.
@main
struct C2VApp: App {
    @State private var monitor: ClipboardMonitor

    /// Persistent SwiftData model container storing clipboard history items.
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CopiedItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Failed to initialize persistent ModelContainer: \(error). Reconstructing database...")
            // Reconstruct store when migration fails or schema is incompatible
            if let storeURL = modelConfiguration.url as URL? {
                let fileManager = FileManager.default
                try? fileManager.removeItem(at: storeURL)
                let walURL = URL(fileURLWithPath: storeURL.path + "-wal")
                let shmURL = URL(fileURLWithPath: storeURL.path + "-shm")
                try? fileManager.removeItem(at: walURL)
                try? fileManager.removeItem(at: shmURL)
                let altWalURL = storeURL.deletingPathExtension().appendingPathExtension("store-wal")
                let altShmURL = storeURL.deletingPathExtension().appendingPathExtension("store-shm")
                try? fileManager.removeItem(at: altWalURL)
                try? fileManager.removeItem(at: altShmURL)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not reconstruct ModelContainer: \(error)")
            }
        }
    }()

    /// Initializes the application and starts monitoring right-click status bar events and clipboard changes.
    init() {
        let clipMonitor = ClipboardMonitor()
        _monitor = State(initialValue: clipMonitor)
        clipMonitor.startMonitoring(modelContext: Self.sharedModelContainer.mainContext)
        MenuBarExtraRightClickMonitor.shared.startMonitoring()
    }

    /// The main scene hierarchy comprising the status bar extra popover and app settings window.
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(monitor)
                .modelContainer(Self.sharedModelContainer)
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

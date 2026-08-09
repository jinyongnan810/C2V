//
//  C2VApp.swift
//  C2V
//

import SwiftData
import SwiftUI

@main
struct C2VApp: App {
    @State private var monitor = ClipboardMonitor()

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
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

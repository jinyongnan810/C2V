//
//  C2VApp.swift
//  C2V
//

import SwiftData
import SwiftUI

@main
struct C2VApp: App {
    @StateObject private var monitor = ClipboardMonitor()

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
        MenuBarExtra("C2V", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(monitor)
                .modelContainer(sharedModelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}

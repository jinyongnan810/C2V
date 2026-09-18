//
//  C2VAppIntents.swift
//  C2V
//

import AppIntents
import AppKit
import Foundation
import SwiftData

/// Siri App Intent to search through copied clipboard history.
struct SearchClipboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Clipboard History"
    static var description = IntentDescription("Searches clipboard snippets saved in C2V.")

    @Parameter(title: "Search Query")
    var query: String

    init() {
        query = ""
    }

    init(query: String) {
        self.query = query
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[CopiedItemEntity]> & ProvidesDialog {
        let results = try await CopiedItemQuery().entities(matching: query)

        if results.isEmpty {
            return .result(
                value: [],
                dialog: IntentDialog("No clipboard items found matching \"\(query)\".")
            )
        } else {
            let count = results.count
            let message = count == 1
                ? "Found 1 matching clipboard snippet."
                : "Found \(count) matching clipboard snippets."
            return .result(
                value: results,
                dialog: IntentDialog(stringLiteral: message)
            )
        }
    }
}

/// Siri App Intent to copy a specific snippet to the system clipboard.
struct CopySnippetIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Snippet to Clipboard"
    static var description = IntentDescription("Puts a selected C2V snippet onto the macOS clipboard.")

    @Parameter(title: "Snippet")
    var snippet: CopiedItemEntity

    init() {}

    init(snippet: CopiedItemEntity) {
        self.snippet = snippet
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(snippet.text, forType: .string)

        // Update creation date to bring item to top in SwiftData
        let context = C2VApp.sharedModelContainer.mainContext
        let targetID = snippet.id
        var descriptor = FetchDescriptor<CopiedItem>(
            predicate: #Predicate { $0.id == targetID }
        )
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            existing.createdAt = Date()
            try? context.save()
        }

        let preview = snippet.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let previewSnippet = preview.count > 30 ? String(preview.prefix(30)) + "…" : preview
        return .result(dialog: IntentDialog("Copied \"\(previewSnippet)\" to your clipboard."))
    }
}

/// Siri App Intent to copy the most recently copied item from history.
struct CopyLatestSnippetIntent: AppIntent {
    static var title: LocalizedStringResource = "Copy Latest Snippet"
    static var description = IntentDescription("Copies the most recent clipboard entry back to your clipboard.")

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String?> & ProvidesDialog {
        let context = C2VApp.sharedModelContainer.mainContext
        var descriptor = FetchDescriptor<CopiedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let latest = try? context.fetch(descriptor).first else {
            return .result(
                value: nil,
                dialog: IntentDialog("No clipboard history found in C2V.")
            )
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(latest.text, forType: .string)

        let preview = latest.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let previewSnippet = preview.count > 30 ? String(preview.prefix(30)) + "…" : preview

        return .result(
            value: latest.text,
            dialog: IntentDialog("Copied latest snippet: \"\(previewSnippet)\".")
        )
    }
}

/// Siri App Intent to clear clipboard history with option to preserve pinned items.
struct ClearClipboardHistoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Clear Clipboard History"
    static var description = IntentDescription("Clears unpinned or all clipboard history in C2V.")

    @Parameter(title: "Include Pinned Snippets", default: false)
    var includePinned: Bool

    init() {
        includePinned = false
    }

    init(includePinned: Bool) {
        self.includePinned = includePinned
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = C2VApp.sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<CopiedItem>()
        guard let allItems = try? context.fetch(descriptor) else {
            return .result(dialog: IntentDialog("Failed to access clipboard history."))
        }

        var deletedCount = 0
        for item in allItems {
            if includePinned || !item.isPinned {
                context.delete(item)
                deletedCount += 1
            }
        }

        try? context.save()

        if includePinned {
            return .result(dialog: IntentDialog("Cleared all \(deletedCount) items from clipboard history."))
        } else {
            return .result(dialog: IntentDialog("Cleared \(deletedCount) unpinned items from clipboard history."))
        }
    }
}

/// Siri App Intent to toggle pinned status for a snippet.
struct TogglePinSnippetIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Pin for Snippet"
    static var description = IntentDescription("Pins or unpins a clipboard snippet in C2V.")

    @Parameter(title: "Snippet")
    var snippet: CopiedItemEntity

    init() {}

    init(snippet: CopiedItemEntity) {
        self.snippet = snippet
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = C2VApp.sharedModelContainer.mainContext
        let targetID = snippet.id
        var descriptor = FetchDescriptor<CopiedItem>(
            predicate: #Predicate { $0.id == targetID }
        )
        descriptor.fetchLimit = 1

        guard let item = try? context.fetch(descriptor).first else {
            return .result(dialog: IntentDialog("Snippet not found."))
        }

        item.isPinned.toggle()
        try? context.save()

        let status = item.isPinned ? "Pinned" : "Unpinned"
        return .result(dialog: IntentDialog("\(status) snippet successfully."))
    }
}

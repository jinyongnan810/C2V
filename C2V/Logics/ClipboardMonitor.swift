//
//  ClipboardMonitor.swift
//  C2V
//

import AppKit
import Foundation
import Observation
import SwiftData

/// Real-time pasteboard polling service that detects new copied text snippets and saves them to SwiftData.
@MainActor
@Observable
final class ClipboardMonitor {
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var cleanupTimer: Timer?
    @ObservationIgnored private var lastChangeCount: Int
    @ObservationIgnored private let pasteboard = NSPasteboard.general
    @ObservationIgnored private var modelContext: ModelContext?

    var lastCopiedText: String?

    /// Initializes the clipboard monitor with the current system pasteboard change count.
    init() {
        lastChangeCount = pasteboard.changeCount
    }

    /// Starts periodic timers: polls pasteboard changes every 0.5s and cleans overflowed unpinned items every 1 hour.
    func startMonitoring(modelContext: ModelContext) {
        self.modelContext = modelContext
        guard timer == nil else { return }

        // Initial sync of lastChangeCount
        lastChangeCount = pasteboard.changeCount

        // Initial trim on startup
        trimOldItemsIfNeeded(modelContext: modelContext)

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let self, let context = self.modelContext {
                    checkPasteboard(modelContext: context)
                }
            }
        }

        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                if let self, let context = self.modelContext {
                    trimOldItemsIfNeeded(modelContext: context)
                }
            }
        }
    }

    /// Stops active pasteboard polling timer and hourly cleanup timer.
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    /// Checks pasteboard for plain text changes, filters out files/images, prevents duplicate consecutive entries, and saves new snippets.
    private func checkPasteboard(modelContext: ModelContext) {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // Check types: Ignore if file URL or binary image file is present
        let types = pasteboard.types ?? []
        if types.contains(.fileURL) || types.contains(NSPasteboard.PasteboardType("public.file-url")) {
            return
        }

        guard let text = pasteboard.string(forType: .string) else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Check if identical to most recent entry to prevent duplicates
        var fetchDescriptor = FetchDescriptor<CopiedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fetchDescriptor.fetchLimit = 1

        do {
            let existingItems = try modelContext.fetch(fetchDescriptor)
            if let latest = existingItems.first, latest.text == text {
                // Already the latest item, no need to add duplicate
                return
            }

            // Insert new copied item
            let newItem = CopiedItem(text: text)
            modelContext.insert(newItem)
            try modelContext.save()

            lastCopiedText = text
        } catch {
            print("Failed to fetch/save copied item: \(error)")
        }
    }

    /// Writes specified text to NSPasteboard, updates change count, and refreshes item creation timestamp to bring it to the top.
    func copyToClipboard(_ text: String, modelContext: ModelContext) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        // Update lastChangeCount so monitoring doesn't treat our own copy as a brand new item
        lastChangeCount = pasteboard.changeCount

        // Optional: Update timestamp of copied item to move it to top
        var fetchDescriptor = FetchDescriptor<CopiedItem>(
            predicate: #Predicate { $0.text == text }
        )
        fetchDescriptor.fetchLimit = 1

        do {
            if let item = try modelContext.fetch(fetchDescriptor).first {
                item.createdAt = Date()
                try modelContext.save()
            }
        } catch {
            print("Failed to update copied item timestamp: \(error)")
        }
    }

    /// Deletes oldest unpinned snippets from persistent store when unpinned item count exceeds maximum limit.
    func trimOldItemsIfNeeded(modelContext: ModelContext, maxLimit: Int? = nil) {
        let limit = maxLimit ?? HistoryLimitManager.currentLimit
        let fetchDescriptor = FetchDescriptor<CopiedItem>(
            predicate: #Predicate { !$0.isPinned },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let unpinnedItems = try modelContext.fetch(fetchDescriptor)
            if unpinnedItems.count > limit {
                let itemsToDeleteCount = unpinnedItems.count - limit
                let itemsToDelete = unpinnedItems.suffix(itemsToDeleteCount)
                for item in itemsToDelete {
                    modelContext.delete(item)
                }
                try modelContext.save()
            }
        } catch {
            print("Failed to trim old items: \(error)")
        }
    }
}

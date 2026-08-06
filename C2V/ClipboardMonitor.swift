//
//  ClipboardMonitor.swift
//  C2V
//

import AppKit
import Combine
import Foundation
import SwiftData

@MainActor
final class ClipboardMonitor: ObservableObject {
    private var timer: Timer?
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general

    @Published var lastCopiedText: String?

    init() {
        lastChangeCount = pasteboard.changeCount
    }

    func startMonitoring(modelContext: ModelContext) {
        stopMonitoring()

        // Initial sync of lastChangeCount
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkPasteboard(modelContext: modelContext)
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

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

            // Trim old unpinned items if over limit (e.g. 100)
            trimOldItemsIfNeeded(modelContext: modelContext)
        } catch {
            print("Failed to fetch/save copied item: \(error)")
        }
    }

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

    private func trimOldItemsIfNeeded(modelContext: ModelContext, maxLimit: Int = 100) {
        let fetchDescriptor = FetchDescriptor<CopiedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let allItems = try modelContext.fetch(fetchDescriptor)
            if allItems.count > maxLimit {
                let unpinnedItems = allItems.filter { !$0.isPinned }
                let itemsToDeleteCount = allItems.count - maxLimit

                // Delete oldest unpinned items
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

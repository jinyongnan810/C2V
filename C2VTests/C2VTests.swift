//
//  C2VTests.swift
//  C2VTests
//

@testable import C2V
import Foundation
import SwiftData
import Testing

/// Unit test suite for verifying C2V data models and core business logic.
struct C2VTests {
    /// Tests the initialization and default property values of a CopiedItem instance.
    @Test func testCopiedItemInitialization() throws {
        let text = "Hello C2V Clipboard"
        let item = CopiedItem(text: text)

        #expect(item.text == text)
        #expect(item.isPinned == false)
        #expect(item.characterCount == text.count)
    }

    /// Tests custom characterCount initialization.
    @Test func testCopiedItemCustomCharacterCount() throws {
        let text = "Custom count snippet"
        let item = CopiedItem(text: text, characterCount: 42)
        #expect(item.characterCount == 42)
    }

    /// Tests toggling the pinning state of a CopiedItem model.
    @Test func testItemPinningToggle() throws {
        let item = CopiedItem(text: "Test snippet")
        #expect(item.isPinned == false)

        item.isPinned.toggle()
        #expect(item.isPinned == true)
    }

    /// Tests history limit default initialization to 50.
    @MainActor
    @Test func testHistoryLimitDefault() throws {
        let suiteName = "C2VTests.HistoryLimit.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            Issue.record("Failed to create isolated UserDefaults suite")
            return
        }
        defer {
            testDefaults.removePersistentDomain(forName: suiteName)
        }

        #expect(testDefaults.object(forKey: HistoryLimitManager.historyLimitKey) == nil)
        HistoryLimitManager.setupDefaultLimitIfNeeded(userDefaults: testDefaults)
        #expect(testDefaults.integer(forKey: HistoryLimitManager.historyLimitKey) == 50)
    }

    /// Tests trimming overflowed unpinned clipboard items while preserving pinned snippets.
    @MainActor
    @Test func testHistoryLimitTrimming() throws {
        let schema = Schema([CopiedItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext

        // Insert 15 unpinned items with incremental timestamps
        for index in 1 ... 15 {
            let item = CopiedItem(text: "Unpinned Snippet \(index)")
            item.createdAt = Date().addingTimeInterval(TimeInterval(index))
            context.insert(item)
        }

        // Insert 2 pinned items
        let pinned1 = CopiedItem(text: "Pinned 1")
        pinned1.isPinned = true
        let pinned2 = CopiedItem(text: "Pinned 2")
        pinned2.isPinned = true
        context.insert(pinned1)
        context.insert(pinned2)
        try context.save()

        // Trim down to max limit of 10
        let monitor = ClipboardMonitor()
        monitor.trimOldItemsIfNeeded(modelContext: context, maxLimit: 10)

        let allItems = try context.fetch(FetchDescriptor<CopiedItem>())
        let unpinnedItems = allItems.filter { !$0.isPinned }
        let pinnedItems = allItems.filter(\.isPinned)

        #expect(unpinnedItems.count == 10)
        #expect(pinnedItems.count == 2)
        #expect(allItems.count == 12)
    }
}

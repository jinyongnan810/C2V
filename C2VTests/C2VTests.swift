//
//  C2VTests.swift
//  C2VTests
//

import AppIntents
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

    /// Tests CopiedItemEntity representation and conversion from SwiftData model.
    @Test func testCopiedItemEntityConversion() throws {
        let item = CopiedItem(text: "Sample clipboard text for entity testing")
        let entity = CopiedItemEntity(from: item)

        #expect(entity.id == item.id)
        #expect(entity.text == item.text)
        #expect(entity.characterCount == item.characterCount)
        #expect(entity.isPinned == false)
        #expect(entity.displayRepresentation.title != "")
    }

    /// Tests SearchClipboardIntent execution and dialog results.
    @MainActor
    @Test func testSearchClipboardIntent() async throws {
        let context = C2VApp.sharedModelContainer.mainContext
        let uniqueWord = "UniqueSnippetWord\(UUID().uuidString.prefix(6))"
        let item = CopiedItem(text: "Test snippet containing \(uniqueWord)")
        context.insert(item)
        try context.save()

        let intent = SearchClipboardIntent(query: String(uniqueWord))
        let result = try await intent.perform()
        let matchingItems = try #require(result.value)
        #expect(matchingItems.count >= 1)
        #expect(matchingItems.contains(where: { $0.text.contains(uniqueWord) }))

        // Clean up
        context.delete(item)
        try context.save()
    }

    /// Tests CopyLatestSnippetIntent fetching and pasteboard copying.
    @MainActor
    @Test func testCopyLatestSnippetIntent() async throws {
        let context = C2VApp.sharedModelContainer.mainContext
        let testText = "Latest snippet for Siri test: \(UUID().uuidString)"
        let item = CopiedItem(text: testText)
        item.createdAt = Date().addingTimeInterval(10)
        context.insert(item)
        try context.save()

        let intent = CopyLatestSnippetIntent()
        let result = try await intent.perform()
        #expect(result.value == testText)

        // Clean up
        context.delete(item)
        try context.save()
    }

    /// Tests FoundationModels AI tool calls on macOS 27 or newer.
    @MainActor
    @Test func testMacOS27FoundationModelTools() async throws {
        #if canImport(FoundationModels)
            if #available(macOS 27.0, *) {
                let context = C2VApp.sharedModelContainer.mainContext
                let aiKeyword = "AIKeyword\(UUID().uuidString.prefix(6))"
                let item = CopiedItem(text: "FoundationModels snippet \(aiKeyword)")
                context.insert(item)
                try context.save()

                let searchTool = SearchClipboardAITool()
                let searchResults = try await searchTool.call(arguments: SearchClipboardAITool.Arguments(query: String(aiKeyword), limit: 5))
                #expect(!searchResults.isEmpty)
                #expect(searchResults.first?.contains(aiKeyword) == true)

                let copyTool = CopySnippetAITool()
                let copyResult = try await copyTool.call(arguments: CopySnippetAITool.Arguments(text: "Copied via AI tool"))
                #expect(copyResult.contains("Successfully copied"))

                // Clean up
                context.delete(item)
                try context.save()
            }
        #endif
    }
}

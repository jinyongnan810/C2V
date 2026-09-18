//
//  CopiedItemEntity.swift
//  C2V
//

import AppIntents
import Foundation
import SwiftData

/// An App Entity representing a copied clipboard snippet in C2V for Siri and system integrations.
struct CopiedItemEntity: AppEntity, Identifiable, Sendable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Clipboard Snippet"

    static var defaultQuery = CopiedItemQuery()

    var id: UUID

    @Property(title: "Text")
    var text: String

    @Property(title: "Created At")
    var createdAt: Date

    @Property(title: "Is Pinned")
    var isPinned: Bool

    @Property(title: "Character Count")
    var characterCount: Int

    var displayRepresentation: DisplayRepresentation {
        let snippet = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = snippet.count > 60 ? String(snippet.prefix(60)) + "…" : snippet
        let dateString = createdAt.formatted(date: .abbreviated, time: .shortened)
        return DisplayRepresentation(
            title: "\(preview)",
            subtitle: "\(dateString) • \(characterCount) chars\(isPinned ? " • Pinned" : "")"
        )
    }

    init(
        id: UUID,
        text: String,
        createdAt: Date,
        isPinned: Bool,
        characterCount: Int
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.characterCount = characterCount
    }

    init(from item: CopiedItem) {
        id = item.id
        text = item.text
        createdAt = item.createdAt
        isPinned = item.isPinned
        characterCount = item.characterCount
    }
}

/// Entity query implementation allowing Siri and Shortcuts to look up snippets by ID or search string.
struct CopiedItemQuery: EntityQuery, EntityStringQuery, Sendable {
    init() {}

    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [CopiedItemEntity] {
        let context = C2VApp.sharedModelContainer.mainContext
        let targetIDs = Set(identifiers)
        let descriptor = FetchDescriptor<CopiedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let items = try context.fetch(descriptor)
        return items
            .filter { targetIDs.contains($0.id) }
            .map { CopiedItemEntity(from: $0) }
    }

    @MainActor
    func suggestedEntities() async throws -> [CopiedItemEntity] {
        let context = C2VApp.sharedModelContainer.mainContext
        var descriptor = FetchDescriptor<CopiedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        let items = try context.fetch(descriptor)
        return items.map { CopiedItemEntity(from: $0) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [CopiedItemEntity] {
        let context = C2VApp.sharedModelContainer.mainContext
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        let descriptor = FetchDescriptor<CopiedItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let items = try context.fetch(descriptor)
        return items
            .filter { $0.text.localizedCaseInsensitiveContains(query) }
            .prefix(20)
            .map { CopiedItemEntity(from: $0) }
    }
}

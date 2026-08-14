//
//  CopiedItem.swift
//  C2V
//

import Foundation
import SwiftData

/// SwiftData model entity representing a single copied text snippet entry.
@Model
final class CopiedItem {
    @Attribute(.unique) var id: UUID
    var text: String
    var createdAt: Date
    var isPinned: Bool
    var characterCount: Int?

    /// Returns the character count, falling back to text.count for legacy migrated records.
    var resolvedCharacterCount: Int {
        characterCount ?? text.count
    }

    /// Initializes a new copied item instance with unique identifier, text content, creation timestamp, pin status, and character count.
    init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        isPinned: Bool = false,
        characterCount: Int? = nil
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.characterCount = characterCount ?? text.count
    }
}

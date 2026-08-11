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

    /// Initializes a new copied item instance with unique identifier, text content, creation timestamp, and pin status.
    init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isPinned = isPinned
    }
}

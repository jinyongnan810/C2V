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
}

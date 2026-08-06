//
//  C2VTests.swift
//  C2VTests
//

@testable import C2V
import Foundation
import SwiftData
import Testing

struct C2VTests {
    @Test func testCopiedItemInitialization() throws {
        let text = "Hello C2V Clipboard"
        let item = CopiedItem(text: text)

        #expect(item.text == text)
        #expect(item.isPinned == false)
    }

    @Test func testItemPinningToggle() throws {
        let item = CopiedItem(text: "Test snippet")
        #expect(item.isPinned == false)

        item.isPinned.toggle()
        #expect(item.isPinned == true)
    }
}

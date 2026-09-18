//
//  C2VAITools.swift
//  C2V
//

import AppKit
import Foundation
import SwiftData

#if canImport(FoundationModels)
    import FoundationModels

    // MARK: - macOS 27+ Foundation Models AI Tools

    /// An AI Tool for on-device Foundation Models to query clipboard history in C2V.
    @available(macOS 27.0, *)
    struct SearchClipboardAITool: Tool {
        let name = "searchClipboard"
        let description = "Searches the user's copied clipboard history in C2V for matching text, topics, or keywords."

        @Generable
        struct Arguments {
            @Guide(description: "Keyword or search phrase to match against clipboard history")
            var query: String

            @Guide(description: "Maximum number of matching snippets to return", .range(1 ... 15))
            var limit: Int

            init(query: String, limit: Int = 5) {
                self.query = query
                self.limit = limit
            }
        }

        init() {}

        @MainActor
        func call(arguments: Arguments) async throws -> [String] {
            let context = C2VApp.sharedModelContainer.mainContext
            let query = arguments.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            let descriptor = FetchDescriptor<CopiedItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let items = try context.fetch(descriptor)

            let matches = items.filter { item in
                query.isEmpty || item.text.localizedCaseInsensitiveContains(query)
            }

            return matches.prefix(arguments.limit).map { item in
                let date = item.createdAt.formatted(date: .abbreviated, time: .shortened)
                let pinLabel = item.isPinned ? " [Pinned]" : ""
                return "[\(date)\(pinLabel)]: \(item.text)"
            }
        }
    }

    /// An AI Tool for on-device Foundation Models to copy a chosen snippet to the macOS pasteboard.
    @available(macOS 27.0, *)
    struct CopySnippetAITool: Tool {
        let name = "copySnippet"
        let description = "Copies a given text snippet onto the macOS system clipboard (pasteboard)."

        @Generable
        struct Arguments {
            @Guide(description: "The exact text to place on the clipboard")
            var text: String

            init(text: String) {
                self.text = text
            }
        }

        init() {}

        @MainActor
        func call(arguments: Arguments) async throws -> String {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(arguments.text, forType: .string)

            // Refresh timestamp if matching in database
            let context = C2VApp.sharedModelContainer.mainContext
            let targetText = arguments.text
            var descriptor = FetchDescriptor<CopiedItem>(
                predicate: #Predicate { $0.text == targetText }
            )
            descriptor.fetchLimit = 1

            if let existing = try? context.fetch(descriptor).first {
                existing.createdAt = Date()
                try? context.save()
            }

            return "Successfully copied to system clipboard."
        }
    }

    /// An AI Tool for on-device Foundation Models to inspect recent clipboard history.
    @available(macOS 27.0, *)
    struct GetRecentSnippetsAITool: Tool {
        let name = "getRecentSnippets"
        let description = "Retrieves the most recent items copied to C2V clipboard history."

        @Generable
        struct Arguments {
            @Guide(description: "The number of recent items to inspect", .range(1 ... 20))
            var count: Int

            init(count: Int = 5) {
                self.count = count
            }
        }

        init() {}

        @MainActor
        func call(arguments: Arguments) async throws -> [String] {
            let context = C2VApp.sharedModelContainer.mainContext
            var descriptor = FetchDescriptor<CopiedItem>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = arguments.count

            let items = try context.fetch(descriptor)
            return items.map { item in
                let date = item.createdAt.formatted(date: .abbreviated, time: .shortened)
                let pinLabel = item.isPinned ? " [Pinned]" : ""
                return "[\(date)\(pinLabel)]: \(item.text)"
            }
        }
    }

    // MARK: - Assistant Session Orchestrator

    /// Manager providing conversational intelligence over clipboard history using macOS 27 Foundation Models.
    @available(macOS 27.0, *)
    @MainActor
    final class C2VAIAssistant {
        static let shared = C2VAIAssistant()

        private var session: LanguageModelSession?

        private init() {}

        /// Creates or resets the language model session configured with C2V AI tools.
        func makeSession() -> LanguageModelSession {
            let tools: [any Tool] = [
                SearchClipboardAITool(),
                CopySnippetAITool(),
                GetRecentSnippetsAITool(),
            ]

            let instructions = Instructions(
                """
                You are an intelligent assistant integrated into C2V, a macOS clipboard manager.
                Your role is to help users retrieve, inspect, synthesize, or re-copy information from their clipboard history.
                You have access to tools to search clipboard entries, inspect recent items, and copy selected text back to the system clipboard.
                Be concise, helpful, and accurate. Never fabricate clipboard items that were not found by tools.
                """
            )

            let session = LanguageModelSession(
                model: SystemLanguageModel.default,
                tools: tools,
                instructions: instructions
            )
            self.session = session
            return session
        }

        /// Queries the assistant with a user request.
        func ask(_ userPrompt: String) async throws -> String {
            let activeSession = session ?? makeSession()
            let response = try await activeSession.respond(to: userPrompt)
            return response.content
        }
    }

#endif

//
//  C2VShortcutsProvider.swift
//  C2V
//

import AppIntents

/// Registers out-of-the-box Siri voice shortcuts and Spotlight capabilities for C2V.
struct C2VShortcutsProvider: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .orange

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CopyLatestSnippetIntent(),
            phrases: [
                "Copy latest in \(.applicationName)",
                "Copy last snippet in \(.applicationName)",
                "Paste last item in \(.applicationName)",
            ],
            shortTitle: "Copy Latest Snippet",
            systemImageName: "doc.on.clipboard"
        )

        AppShortcut(
            intent: SearchClipboardIntent(),
            phrases: [
                "Search clipboard in \(.applicationName)",
                "Find copied text in \(.applicationName)",
                "Search snippets in \(.applicationName)",
            ],
            shortTitle: "Search Clipboard",
            systemImageName: "magnifyingglass"
        )

        AppShortcut(
            intent: ClearClipboardHistoryIntent(),
            phrases: [
                "Clear clipboard history with \(.applicationName)",
                "Clean clipboard in \(.applicationName)",
            ],
            shortTitle: "Clear History",
            systemImageName: "trash"
        )
    }
}

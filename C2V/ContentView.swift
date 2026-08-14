//
//  ContentView.swift
//  C2V
//

import SwiftData
import SwiftUI

/// Main popover view for searching, managing, inspecting, and clearing copied text snippets.
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \CopiedItem.createdAt, order: .reverse) private var items: [CopiedItem]

    @Environment(ClipboardMonitor.self) private var monitor: ClipboardMonitor

    @State private var searchText: String = ""
    @State private var filterPinnedOnly: Bool = false
    @State private var copiedToastItemText: String? = nil
    @State private var showClearConfirmation: Bool = false
    @State private var isScrolledDown: Bool = false
    @State private var selectedQuickLookItem: CopiedItem? = nil
    @State private var isQuickLookCopied: Bool = false
    @FocusState private var isSearchFocused: Bool

    /// Filters clipboard items based on active search keyword and pin status filter, prioritizing pinned items.
    var filteredItems: [CopiedItem] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let candidateItems: [CopiedItem]
        if trimmedSearch.isEmpty {
            if filterPinnedOnly {
                return items.filter(\.isPinned)
            } else {
                candidateItems = items
            }
        } else {
            candidateItems = items.filter { item in
                let matchesSearch = item.text.localizedCaseInsensitiveContains(trimmedSearch)
                let matchesPin = !filterPinnedOnly || item.isPinned
                return matchesSearch && matchesPin
            }
        }

        if filterPinnedOnly || !candidateItems.contains(where: \.isPinned) {
            return candidateItems
        }

        let pinned = candidateItems.filter(\.isPinned)
        let unpinned = candidateItems.filter { !$0.isPinned }
        return pinned + unpinned
    }

    /// Total count of items currently pinned by the user.
    private var pinnedCount: Int {
        items.filter(\.isPinned).count
    }

    /// Renders the main view hierarchy including header, search bar, list container, and modal overlays.
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header
                headerView

                Divider()

                // Search & Filter Bar
                searchAndFilterBar

                Divider()

                // Clipboard List
                ZStack {
                    if filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        itemList
                    }

                    // Toast notification when item is copied
                    if let text = copiedToastItemText {
                        toastOverlay(text: text)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: copiedToastItemText)
                    }
                }

                Divider()

                // Footer
                footerView
            }

            // Confirmation Overlay for MenuBarExtra
            if showClearConfirmation {
                ClearConfirmationOverlay(
                    onClearUnpinned: {
                        withAnimation {
                            clearUnpinnedItems()
                            showClearConfirmation = false
                        }
                    },
                    onClearAll: {
                        withAnimation {
                            clearAllItems()
                            showClearConfirmation = false
                        }
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showClearConfirmation = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Quick Look Inspector Overlay
            if let item = selectedQuickLookItem {
                QuickLookOverlay(
                    item: item,
                    isQuickLookCopied: isQuickLookCopied,
                    onClose: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedQuickLookItem = nil
                            isQuickLookCopied = false
                        }
                    },
                    onCopy: {
                        copyItem(item)
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isQuickLookCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isQuickLookCopied = false
                            }
                        }
                    },
                    onTogglePin: {
                        togglePin(item)
                    },
                    onDelete: {
                        deleteItem(item)
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(width: 360, height: 480)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = false
        }
        .liquidGlassEffect(in: Rectangle())
        .onAppear {
            monitor.startMonitoring(modelContext: modelContext)
            DispatchQueue.main.async {
                isSearchFocused = false
            }
        }
    }

    // MARK: - Subviews

    /// Header view containing app status icon, clear history trigger, and settings button.
    @ViewBuilder
    private var headerView: some View {
        HStack {
            Image("TrayIcon")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    showClearConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .liquidGlassEffect(in: Circle())
                }
                .buttonStyle(.plain)
                .help("Clear History")
                .accessibilityLabel(Text("Clear History"))
                .accessibilityHint(Text("Opens confirmation dialog to clear copied items"))

                Button {
                    openSettingsWindow()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(width: 28, height: 28)
                        .liquidGlassEffect(in: Circle())
                }
                .buttonStyle(.plain)
                .help("Settings")
                .accessibilityLabel(Text("Settings"))
                .accessibilityHint(Text("Opens application settings window"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassEffect(in: Rectangle())
    }

    /// Search bar input field with clear button and pin filter toggle button.
    @ViewBuilder
    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary.opacity(0.7))
                    .accessibilityHidden(true)
                TextField("Search copied text...", text: $searchText)
                    .focused($isSearchFocused)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .accessibilityLabel(Text("Search copied text"))

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Clear search text"))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 12).stroke(.secondary)
            }

            Button {
                if reduceMotion {
                    filterPinnedOnly.toggle()
                } else {
                    withAnimation {
                        filterPinnedOnly.toggle()
                    }
                }
            } label: {
                Image(systemName: filterPinnedOnly ? "pin.fill" : "pin")
                    .font(.subheadline)
                    .foregroundColor(filterPinnedOnly ? .orange : .primary)
                    .frame(width: 28, height: 28)
                    .liquidGlassEffect(in: Circle())
            }
            .buttonStyle(.plain)
            .help(filterPinnedOnly ? "Show All Items" : "Filter Pinned Items")
            .accessibilityLabel(Text(filterPinnedOnly ? "Show All Items" : "Filter Pinned Items"))
            .accessibilityHint(Text(filterPinnedOnly ? "Shows unpinned and pinned items" : "Filters list to display pinned items only"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    /// Scrollable list displaying copied items with scroll-to-top detection.
    @ViewBuilder
    private var itemList: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                List {
                    Color.clear
                        .frame(height: 0.5)
                        .id("scrollTopTarget")
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isScrolledDown = false
                            }
                        }
                        .onDisappear {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isScrolledDown = true
                            }
                        }

                    ForEach(filteredItems) { item in
                        CopiedItemRow(item: item) {
                            copyItem(item)
                        } onTogglePin: {
                            togglePin(item)
                        } onDelete: {
                            deleteItem(item)
                        } onQuickLook: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedQuickLookItem = item
                                isQuickLookCopied = false
                            }
                        }
                        .id(item.id)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)

                if isScrolledDown {
                    ScrollToTopButton {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("scrollTopTarget", anchor: .top)
                        }
                    }
                    .padding(.trailing, 14)
                    .padding(.bottom, 14)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    /// Placeholder view displayed when no items match search query or clipboard history is empty.
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 36))
                .foregroundColor(.secondary.opacity(0.6))

            Text(searchText.isEmpty ? "No Copied Text Yet" : "No Matching Results")
                .font(.headline)
                .foregroundColor(.secondary)

            Text(searchText.isEmpty ? "Copy any text on your Mac to automatically save it here." : "Try searching for a different keyword.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Toast notification banner displayed temporarily when a snippet is copied to clipboard.
    @ViewBuilder
    private func toastOverlay(text _: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .accessibilityHidden(true)
                Text("Copied to clipboard!")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .liquidGlassEffect(in: Capsule())
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.bottom, 20)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Copied to clipboard"))
    }

    /// Footer bar displaying total items count and pinned items count.
    @ViewBuilder
    private var footerView: some View {
        HStack {
            HStack(spacing: 4) {
                Text("\(filteredItems.count) items")

                if pinnedCount > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text("\(pinnedCount) pinned")
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .accessibilityElement(children: .combine)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Helper Methods

    /// Activates application and presents the macOS Settings window.
    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            openSettings()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    /// Re-copies selected snippet text to pasteboard and displays copy confirmation toast.
    private func copyItem(_ item: CopiedItem) {
        monitor.copyToClipboard(item.text, modelContext: modelContext)
        withAnimation {
            copiedToastItemText = item.text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                if copiedToastItemText == item.text {
                    copiedToastItemText = nil
                }
            }
        }
    }

    /// Toggles pinned state of specified clipboard item in SwiftData context.
    private func togglePin(_ item: CopiedItem) {
        withAnimation {
            item.isPinned.toggle()
            try? modelContext.save()
        }
    }

    /// Deletes specified snippet from SwiftData model context.
    private func deleteItem(_ item: CopiedItem) {
        if selectedQuickLookItem?.id == item.id {
            selectedQuickLookItem = nil
            isQuickLookCopied = false
        }
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    /// Deletes all non-pinned clipboard items from SwiftData context.
    private func clearUnpinnedItems() {
        if let current = selectedQuickLookItem, !current.isPinned {
            selectedQuickLookItem = nil
            isQuickLookCopied = false
        }
        withAnimation {
            let unpinned = items.filter { !$0.isPinned }
            for item in unpinned {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }

    /// Deletes all history items including pinned snippets from SwiftData context.
    private func clearAllItems() {
        selectedQuickLookItem = nil
        isQuickLookCopied = false
        withAnimation {
            for item in items {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
}

#Preview {
    ContentView()
        .environment(ClipboardMonitor())
        .modelContainer(for: CopiedItem.self, inMemory: true)
}

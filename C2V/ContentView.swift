//
//  ContentView.swift
//  C2V
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openSettings) private var openSettings
    @Query private var items: [CopiedItem]

    @Environment(ClipboardMonitor.self) private var monitor: ClipboardMonitor

    @State private var searchText: String = ""
    @State private var filterPinnedOnly: Bool = false
    @State private var copiedToastItemText: String? = nil
    @State private var showClearConfirmation: Bool = false
    @State private var isScrolledDown: Bool = false
    @State private var selectedQuickLookItem: CopiedItem? = nil
    @State private var isQuickLookCopied: Bool = false

    var filteredItems: [CopiedItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty || item.text.localizedCaseInsensitiveContains(searchText)
            let matchesPin = !filterPinnedOnly || item.isPinned
            return matchesSearch && matchesPin
        }.sorted { a, b -> Bool in
            if a.isPinned != b.isPinned {
                return a.isPinned && !b.isPinned
            }
            return a.createdAt > b.createdAt
        }
    }

    private var pinnedCount: Int {
        items.filter(\.isPinned).count
    }

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
        .liquidGlassEffect(in: Rectangle())
        .onAppear {
            monitor.startMonitoring(modelContext: modelContext)
        }
    }

    // MARK: - Subviews

    @ContentBuilder
    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image("TrayIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text("C2V")
                    .font(.headline)
                    .fontWeight(.bold)
            }

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
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .liquidGlassEffect(in: Rectangle())
    }

    @ContentBuilder
    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary.opacity(0.7))
                TextField("Search copied text...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.primary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .liquidGlassEffect(in: RoundedRectangle(cornerRadius: 8))

            Button {
                withAnimation {
                    filterPinnedOnly.toggle()
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ContentBuilder
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

    @ContentBuilder
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

    @ContentBuilder
    private func toastOverlay(text _: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
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
    }

    @ContentBuilder
    private var footerView: some View {
        HStack {
            HStack(spacing: 4) {
                Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")

                if pinnedCount > 0 {
                    Text("•")
                        .foregroundColor(.secondary)
                    HStack(spacing: 3) {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(pinnedCount) pinned")
                    }
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Spacer()

            Button("Quit C2V") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .liquidGlassEffect(in: Rectangle())
    }

    // MARK: - Helper Methods

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            openSettings()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

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

    private func togglePin(_ item: CopiedItem) {
        withAnimation {
            item.isPinned.toggle()
            try? modelContext.save()
        }
    }

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

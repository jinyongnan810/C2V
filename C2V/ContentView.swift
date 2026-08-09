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
                clearConfirmationOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }

            // Quick Look Inspector Overlay
            if let item = selectedQuickLookItem {
                quickLookOverlay(item: item)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(width: 360, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            monitor.startMonitoring(modelContext: modelContext)
        }
    }

    // MARK: - Header

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
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Clear History")

                Button {
                    openSettingsWindow()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Settings")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    // MARK: - Search & Filter

    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search copied text...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )

            Button {
                withAnimation {
                    filterPinnedOnly.toggle()
                }
            } label: {
                Image(systemName: filterPinnedOnly ? "pin.fill" : "pin")
                    .font(.subheadline)
                    .foregroundColor(filterPinnedOnly ? .orange : .secondary)
                    .padding(6)
                    .background(filterPinnedOnly ? Color.orange.opacity(0.15) : Color.clear)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help(filterPinnedOnly ? "Show All Items" : "Filter Pinned Items")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Item List

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

    // MARK: - Empty State

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

    // MARK: - Toast Overlay

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
            .background(.thinMaterial)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Footer

    private var pinnedCount: Int {
        items.filter(\.isPinned).count
    }

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
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }

    private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14.0, *) {
            openSettings()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    // MARK: - Clear Confirmation Overlay

    private var clearConfirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showClearConfirmation = false
                    }
                }

            VStack(spacing: 14) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.red)

                VStack(spacing: 4) {
                    Text("Clear Clipboard History?")
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("This action cannot be undone. Choose whether to keep pinned items or clear everything.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }

                VStack(spacing: 8) {
                    Button(role: .destructive) {
                        withAnimation {
                            clearUnpinnedItems()
                            showClearConfirmation = false
                        }
                    } label: {
                        Text("Clear Unpinned Items")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Button(role: .destructive) {
                        withAnimation {
                            clearAllItems()
                            showClearConfirmation = false
                        }
                    } label: {
                        Text("Clear Everything")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Button(role: .cancel) {
                        withAnimation {
                            showClearConfirmation = false
                        }
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Actions

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

    // MARK: - Quick Look Overlay

    private func quickLookOverlay(item: CopiedItem) -> some View {
        let wordCount = item.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let lineCount = item.text.components(separatedBy: .newlines).count

        return ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedQuickLookItem = nil
                        isQuickLookCopied = false
                    }
                }

            VStack(spacing: 12) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .foregroundColor(.accentColor)
                        Text("Quick Look")
                            .font(.headline)
                            .fontWeight(.bold)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selectedQuickLookItem = nil
                            isQuickLookCopied = false
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }

                // Item Metadata Stats Bar
                HStack(spacing: 12) {
                    Label("\(item.text.count) chars", systemImage: "textformat")
                    Label("\(wordCount) words", systemImage: "doc.text")
                    Label("\(lineCount) lines", systemImage: "line.3.horizontal")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)

                // Scrollable Full Text Display
                ScrollView {
                    Text(item.text)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )

                // Footer Actions
                HStack(spacing: 10) {
                    Button {
                        copyItem(item)
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isQuickLookCopied = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isQuickLookCopied = false
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isQuickLookCopied ? "checkmark" : "doc.on.doc")
                            Text(isQuickLookCopied ? "Copied!" : "Copy Text")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isQuickLookCopied ? .green : .accentColor)

                    Button {
                        togglePin(item)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: item.isPinned ? "pin.slash.fill" : "pin.fill")
                            Text(item.isPinned ? "Unpin" : "Pin")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(item.isPinned ? .orange : .primary)

                    Button(role: .destructive) {
                        deleteItem(item)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding(16)
            .frame(maxWidth: 320, maxHeight: 420)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Row Subview

struct CopiedItemRow: View {
    let item: CopiedItem
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    let onQuickLook: () -> Void

    @State private var isHovered: Bool = false

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    var body: some View {
        Button(action: onCopy) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    FadedItemText(text: item.text)

                    if item.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }

                HStack {
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(item.text.count) chars")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: onQuickLook) {
                            Image(systemName: "eye")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .help("Quick Look")

                        Button(action: onTogglePin) {
                            Image(systemName: item.isPinned ? "pin.slash.fill" : "pin")
                                .font(.caption)
                                .foregroundColor(item.isPinned ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "Unpin" : "Pin to Top")

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(isHovered)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.secondary.opacity(0.12) : Color(NSColor.controlBackgroundColor).opacity(0.4))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(item.isPinned ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hover
            }
        }
    }
}

// MARK: - Faded 4-Line Text View

struct FadedItemText: View {
    let text: String

    private static let maxHeight: CGFloat = 72
    private static let solidHeight: CGFloat = 44

    var body: some View {
        Text(text)
            .font(.body)
            .multilineTextAlignment(.leading)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: Self.maxHeight, alignment: .topLeading)
            .clipped()
            .mask(alignment: .top) {
                VStack(spacing: 0) {
                    Color.black
                        .frame(height: Self.solidHeight)
                    LinearGradient(
                        colors: [.black, .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: Self.maxHeight, alignment: .top)
            }
    }
}

// MARK: - Scroll To Top Button

struct ScrollToTopButton: View {
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isHovered ? .accentColor : .primary)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(isHovered ? 0.3 : 0.18), radius: isHovered ? 6 : 4, x: 0, y: 2)
                .overlay(
                    Circle()
                        .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.15), lineWidth: 1)
                )
                .scaleEffect(isHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hover
            }
        }
        .help("Go to Top")
    }
}

#Preview {
    ContentView()
        .environment(ClipboardMonitor())
        .modelContainer(for: CopiedItem.self, inMemory: true)
}

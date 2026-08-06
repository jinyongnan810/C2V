//
//  ContentView.swift
//  C2V
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [CopiedItem]

    @EnvironmentObject private var monitor: ClipboardMonitor
    @StateObject private var launchAtLogin = LaunchAtLoginManager()

    @State private var searchText: String = ""
    @State private var filterPinnedOnly: Bool = false
    @State private var copiedToastItemText: String? = nil
    @State private var showSettingsPopover: Bool = false
    @State private var showClearConfirmation: Bool = false

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
        .frame(width: 360, height: 480)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            monitor.startMonitoring(modelContext: modelContext)
            launchAtLogin.checkStatus()
        }
        .confirmationDialog(
            "Clear History",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Unpinned Items", role: .destructive) {
                clearUnpinnedItems()
            }
            Button("Clear Everything", role: .destructive) {
                clearAllItems()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete stored copied text history?")
        }
        .popover(isPresented: $showSettingsPopover, arrowEdge: .top) {
            settingsPopoverView
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
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
                    showSettingsPopover.toggle()
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
        ScrollViewReader { _ in
            List {
                ForEach(filteredItems) { item in
                    CopiedItemRow(item: item) {
                        copyItem(item)
                    } onTogglePin: {
                        togglePin(item)
                    } onDelete: {
                        deleteItem(item)
                    }
                    .id(item.id)
                    .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
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

    private var footerView: some View {
        HStack {
            Text("\(filteredItems.count) item\(filteredItems.count == 1 ? "" : "s")")
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

    // MARK: - Settings Popover

    private var settingsPopoverView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button {
                    showSettingsPopover = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            Toggle(isOn: Binding(
                get: { launchAtLogin.isEnabled },
                set: { launchAtLogin.setLaunchAtLogin(enabled: $0) }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Start on Boot")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Launch C2V automatically when macOS starts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("C2V Clipboard History")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text("Stores up to 100 text snippets locally on your Mac. Files and images are excluded.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 280)
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
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func clearUnpinnedItems() {
        withAnimation {
            let unpinned = items.filter { !$0.isPinned }
            for item in unpinned {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }

    private func clearAllItems() {
        withAnimation {
            for item in items {
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
}

// MARK: - Row Subview

struct CopiedItemRow: View {
    let item: CopiedItem
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

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
                    Text(item.text)
                        .font(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)

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

#Preview {
    ContentView()
        .environmentObject(ClipboardMonitor())
        .modelContainer(for: CopiedItem.self, inMemory: true)
}

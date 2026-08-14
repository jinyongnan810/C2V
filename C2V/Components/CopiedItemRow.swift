//
//  CopiedItemRow.swift
//  C2V
//

import SwiftUI

/// Interactive card row displaying copied text snippet preview, metadata, and hover action buttons.
struct CopiedItemRow: View {
    let item: CopiedItem
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    let onQuickLook: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered: Bool = false

    private static let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    /// Returns an abbreviated relative timestamp string for the snippet creation date.
    private var formattedDate: String {
        Self.relativeDateTimeFormatter.localizedString(for: item.createdAt, relativeTo: Date())
    }

    /// A truncated preview of the snippet text capped at 200 characters for performant rendering and accessibility.
    private var previewText: String {
        String(item.text.prefix(200))
    }

    /// Renders the card row layout with text preview, metadata labels, and hover action buttons.
    var body: some View {
        Button(action: onCopy) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(previewText)
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

                    Text("\(item.resolvedCharacterCount) chars")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 6) {
                        Button(action: onQuickLook) {
                            Image(systemName: "eye")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .frame(width: 24, height: 24)
                                .liquidGlassEffect(in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Quick Look")
                        .accessibilityLabel(Text("Quick Look"))

                        Button(action: onTogglePin) {
                            Image(systemName: item.isPinned ? "pin.slash.fill" : "pin")
                                .font(.caption)
                                .foregroundColor(item.isPinned ? .orange : .primary)
                                .frame(width: 24, height: 24)
                                .liquidGlassEffect(in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "Unpin" : "Pin to Top")
                        .accessibilityLabel(Text(item.isPinned ? "Unpin item" : "Pin item to top"))

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                                .liquidGlassEffect(in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                        .accessibilityLabel(Text("Delete item"))
                    }
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(isHovered)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.primary.opacity(0.2) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(item.isPinned ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(previewText), \(formattedDate), \(item.resolvedCharacterCount) characters\(item.isPinned ? ", pinned" : "")"))
        .accessibilityHint(Text("Double tap to copy text snippet to clipboard"))
        .accessibilityAction(named: Text("Quick Look")) {
            onQuickLook()
        }
        .accessibilityAction(named: Text(item.isPinned ? "Unpin item" : "Pin item to top")) {
            onTogglePin()
        }
        .accessibilityAction(named: Text("Delete item")) {
            onDelete()
        }
        .onHover { hover in
            if reduceMotion {
                isHovered = hover
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hover
                }
            }
        }
    }
}

//
//  CopiedItemRow.swift
//  C2V
//

import SwiftUI

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

                        Button(action: onTogglePin) {
                            Image(systemName: item.isPinned ? "pin.slash.fill" : "pin")
                                .font(.caption)
                                .foregroundColor(item.isPinned ? .orange : .primary)
                                .frame(width: 24, height: 24)
                                .liquidGlassEffect(in: Circle())
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "Unpin" : "Pin to Top")

                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(width: 24, height: 24)
                                .liquidGlassEffect(in: Circle())
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
                    .fill(isHovered ? Color.primary.opacity(0.2) : Color.primary.opacity(0.03))
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

//
//  QuickLookOverlay.swift
//  C2V
//

import SwiftUI

struct QuickLookOverlay: View {
    let item: CopiedItem
    let isQuickLookCopied: Bool
    let onClose: () -> Void
    let onCopy: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    private var wordCount: Int {
        item.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    private var lineCount: Int {
        item.text.components(separatedBy: .newlines).count
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
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
                        onClose()
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
                        onCopy()
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
                        onTogglePin()
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
                        onDelete()
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

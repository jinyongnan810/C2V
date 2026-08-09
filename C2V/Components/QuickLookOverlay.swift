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
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 28, height: 28)
                            .liquidGlassEffect(in: Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }

                // Item Metadata Stats Bar
                HStack(spacing: 16) {
                    Label("\(item.text.count) chars", systemImage: "textformat")
                    Label("\(wordCount) words", systemImage: "doc.text")
                    Label("\(lineCount) lines", systemImage: "line.3.horizontal")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .liquidGlassEffect(in: RoundedRectangle(cornerRadius: 6))

                // Scrollable Full Text Display
                ScrollView {
                    Text(item.text)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }

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
                    .liquidGlassButtonStyle(isProminent: true, tint: isQuickLookCopied ? .green : .accentColor)

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
                    .liquidGlassButtonStyle(isProminent: false, tint: item.isPinned ? .orange : .primary)

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
                    .liquidGlassButtonStyle(isProminent: false, tint: .red)
                }
            }
            .padding(16)
            .frame(maxWidth: 320, maxHeight: 420)
            .liquidGlassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
    }
}

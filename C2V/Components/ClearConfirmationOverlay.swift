//
//  ClearConfirmationOverlay.swift
//  C2V
//

import SwiftUI

struct ClearConfirmationOverlay: View {
    let onClearUnpinned: () -> Void
    let onClearAll: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
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
                        onClearUnpinned()
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
                        onClearAll()
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
                        onCancel()
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
}

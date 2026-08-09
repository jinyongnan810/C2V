//
//  ScrollToTopButton.swift
//  C2V
//

import SwiftUI

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
    ScrollToTopButton {}
        .padding()
}

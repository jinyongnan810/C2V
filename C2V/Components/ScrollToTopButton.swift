//
//  ScrollToTopButton.swift
//  C2V
//

import SwiftUI

/// Floating action button allowing users to smoothly scroll back to the top of the history list.
struct ScrollToTopButton: View {
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered: Bool = false

    /// Renders circular glassmorphic button with up arrow icon and hover animation effects.
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isHovered ? .accentColor : .primary)
                .frame(width: 32, height: 32)
                .liquidGlassEffect(in: Circle())
                .scaleEffect(isHovered && !reduceMotion ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            if reduceMotion {
                isHovered = hover
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hover
                }
            }
        }
        .help("Go to Top")
        .accessibilityLabel(Text("Scroll to top"))
        .accessibilityHint(Text("Scrolls clipboard list back to top"))
    }
}

#Preview {
    ScrollToTopButton {}
        .padding()
}

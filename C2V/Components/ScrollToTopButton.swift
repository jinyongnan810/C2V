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
                .liquidGlassEffect(in: Circle())
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

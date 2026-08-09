//
//  FadedItemText.swift
//  C2V
//

import SwiftUI

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

#Preview {
    FadedItemText(text: "Sample preview text for testing faded line output.")
        .padding()
}

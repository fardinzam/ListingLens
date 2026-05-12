//
//  SignalBadge.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct SignalBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityElement(children: .combine)
    }
}

#Preview {
    HStack {
        SignalBadge(text: "Verified", systemImage: "checkmark.seal.fill", tint: .green)
        SignalBadge(text: "Guest reported", systemImage: "exclamationmark.triangle.fill", tint: .red)
    }
    .padding()
}

//
//  StaleDataBanner.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct StaleDataBanner: View {
    var body: some View {
        Label("Syncing latest data...", systemImage: "arrow.triangle.2.circlepath")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: Capsule())
            .accessibilityLabel("Showing cached data while syncing the latest information")
            .accessibilityIdentifier("stale-data-banner")
    }
}

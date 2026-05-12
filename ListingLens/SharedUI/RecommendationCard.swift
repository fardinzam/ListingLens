//
//  RecommendationCard.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct RecommendationCard: View {
    let recommendation: Recommendation
    let complete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

                SignalBadge(
                    text: recommendation.status.rawValue.capitalized,
                    systemImage: statusIcon,
                    tint: statusTint
                )
            }

            Text(recommendation.hostAction)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(recommendation.expectedImpact)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                withAnimation(.snappy) {
                    complete()
                }
            } label: {
                Label("Complete", systemImage: "checkmark.circle")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .disabled(recommendation.status == .completed)
            .accessibilityIdentifier("complete-recommendation-\(recommendation.id)")
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
    }

    private var statusIcon: String {
        switch recommendation.status {
        case .suggested:
            "sparkles"
        case .dismissed:
            "xmark.circle"
        case .completed:
            "checkmark.circle.fill"
        }
    }

    private var statusTint: Color {
        switch recommendation.status {
        case .suggested:
            .blue
        case .dismissed:
            .secondary
        case .completed:
            .green
        }
    }
}

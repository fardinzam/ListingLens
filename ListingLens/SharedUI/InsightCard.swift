//
//  InsightCard.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct InsightCard: View {
    let insight: PrimaryInsight?
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                SignalBadge(
                    text: severityText,
                    systemImage: severityIcon,
                    tint: severityColor
                )

                Text("Primary insight")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(insight?.title ?? "No urgent risk signal")
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(insight?.explanation ?? "Listing quality signals look steady. Keep monitoring guest feedback.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                Label(actionTitle, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
    }

    private var severityText: String {
        switch insight?.severity {
        case .critical:
            "Critical"
        case .high:
            "High priority"
        case .medium:
            "Medium"
        case .low:
            "Low"
        case nil:
            "Stable"
        }
    }

    private var severityIcon: String {
        switch insight?.severity {
        case .critical, .high:
            "exclamationmark.triangle.fill"
        case .medium:
            "exclamationmark.circle.fill"
        case .low, nil:
            "checkmark.seal.fill"
        }
    }

    private var severityColor: Color {
        switch insight?.severity {
        case .critical, .high:
            .red
        case .medium:
            .orange
        case .low, nil:
            .green
        }
    }
}

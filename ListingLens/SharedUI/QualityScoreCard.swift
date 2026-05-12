//
//  QualityScoreCard.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct QualityScoreCard: View {
    let score: Int
    let trend: TrendDirection

    private var clampedScore: Int {
        min(max(score, 0), 100)
    }

    private var trendLabel: String {
        switch trend {
        case .improving:
            "Improving"
        case .stable:
            "Stable"
        case .declining:
            "Declining"
        case .insufficientData:
            "Insufficient data"
        }
    }

    private var trendIcon: String {
        switch trend {
        case .improving:
            "arrow.up.right"
        case .stable:
            "equal"
        case .declining:
            "arrow.down.right"
        case .insufficientData:
            "questionmark"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving:
            .green
        case .stable:
            .blue
        case .declining:
            .orange
        case .insufficientData:
            .secondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(.quaternary, lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: Double(clampedScore) / 100)
                        .stroke(
                            trendColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(clampedScore)")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        Text("/100")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 108, height: 108)
                .accessibilityLabel("Quality score \(clampedScore) out of 100")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Quality Score")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(scoreHeadline)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    SignalBadge(text: trendLabel, systemImage: trendIcon, tint: trendColor)
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
    }

    private var scoreHeadline: String {
        switch clampedScore {
        case 90...100:
            "Excellent guest trust"
        case 80..<90:
            "Strong, with a watch item"
        case 65..<80:
            "Needs focused attention"
        default:
            "High-priority quality risk"
        }
    }
}

#Preview {
    QualityScoreCard(score: 84, trend: .declining)
        .padding()
}

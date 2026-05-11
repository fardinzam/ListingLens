//
//  ScoringEngine.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

enum ScoringEngine {
    nonisolated static func score(for listing: Listing) -> Int {
        guard let report = listing.qualityReport else {
            return 0
        }

        return score(
            cleanliness: report.cleanlinessScore,
            accuracy: report.accuracyScore,
            communication: report.communicationScore,
            safety: report.safetyScore,
            accessibility: report.accessibilityScore
        )
    }

    nonisolated static func score(
        cleanliness: Int,
        accuracy: Int,
        communication: Int,
        safety: Int,
        accessibility: Int
    ) -> Int {
        let weightedTotal =
            Double(clamped(cleanliness)) * QualityScore.cleanlinessWeight +
            Double(clamped(accuracy)) * QualityScore.accuracyWeight +
            Double(clamped(communication)) * QualityScore.communicationWeight +
            Double(clamped(safety)) * QualityScore.safetyWeight +
            Double(clamped(accessibility)) * QualityScore.accessibilityWeight

        let totalWeight =
            QualityScore.cleanlinessWeight +
            QualityScore.accuracyWeight +
            QualityScore.communicationWeight +
            QualityScore.safetyWeight +
            QualityScore.accessibilityWeight

        guard totalWeight > 0 else {
            return 0
        }

        return Int((weightedTotal / totalWeight).rounded())
    }

    nonisolated private static func clamped(_ score: Int) -> Int {
        min(max(score, 0), 100)
    }
}

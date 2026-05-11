//
//  ScoringEngineTests.swift
//  ListingLensTests
//
//  Created by Fardin Zaman on 5/11/26.
//

import Testing
@testable import ListingLens

struct ScoringEngineTests {

    @MainActor
    @Test func perfectListingScoresOneHundred() {
        let listing = makeListing(
            cleanliness: 100,
            accuracy: 100,
            communication: 100,
            safety: 100,
            accessibility: 100
        )

        let score = ScoringEngine.score(for: listing)

        #expect(score == 100)
    }

    @MainActor
    @Test func safetyIssueDropsScoreSignificantlyBecauseSafetyHasHighestWeight() {
        let listing = makeListing(
            cleanliness: 100,
            accuracy: 100,
            communication: 100,
            safety: 0,
            accessibility: 100
        )

        let score = ScoringEngine.score(for: listing)

        // Safety has the largest weight because guest harm matters more than polish.
        // With every other category perfect, a zero safety score should still pull
        // the weighted score well below an excellent/reliable listing threshold.
        #expect(score < 80)
    }

    @MainActor
    @Test func missingQualityReportReturnsZeroInsteadOfCrashing() {
        let listing = Listing(
            title: "",
            location: "",
            thumbnailURL: nil,
            host: nil,
            qualityReport: nil
        )

        let score = ScoringEngine.score(for: listing)

        // Missing data is treated as insufficient evidence, not optimistic quality.
        // Returning zero is intentionally conservative until freshness/confidence
        // metadata can distinguish "unknown" from "known bad" in a later iteration.
        #expect(score == 0)
    }

    @MainActor
    private func makeListing(
        cleanliness: Int,
        accuracy: Int,
        communication: Int,
        safety: Int,
        accessibility: Int
    ) -> Listing {
        let report = QualityReport(
            overallScore: 0,
            cleanlinessScore: cleanliness,
            accuracyScore: accuracy,
            communicationScore: communication,
            safetyScore: safety,
            accessibilityScore: accessibility,
            reviewSentiments: []
        )

        return Listing(
            title: "Test Listing",
            location: "San Francisco, CA",
            thumbnailURL: nil,
            host: nil,
            qualityReport: report
        )
    }
}

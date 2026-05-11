//
//  HostDashboardViewModelTests.swift
//  ListingLensTests
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import Testing
@testable import ListingLens

struct HostDashboardViewModelTests {

    @MainActor
    @Test func loadUsesStaleWhileRefreshAndShowsStaleBanner() async throws {
        let listing = makeListing()
        let repository = StubListingRepository(
            stream: [
                DataSnapshot(
                    value: listing,
                    source: .cache,
                    fetchedAt: .distantPast,
                    isStale: true,
                    isOfflineFallback: false,
                    refreshError: nil
                )
            ]
        )
        let viewModel = HostDashboardViewModel(repository: repository)

        viewModel.load()
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(repository.requestedPolicy == .staleWhileRefresh)
        #expect(viewModel.showsStaleDataBanner)

        guard case let .loaded(data) = viewModel.state else {
            Issue.record("Expected loaded dashboard data.")
            return
        }

        #expect(data.listing.id == "stay_1001")
        #expect(data.qualityReport.overallScore == 84)
    }

    @MainActor
    @Test func primaryInsightUsesHighestSeverityThenFrequencyRiskSignal() async throws {
        let report = Self.makeQualityReport(
            riskSignals: [
                QualitySignal(
                    id: "medium_frequent",
                    category: "accuracy",
                    severity: .medium,
                    claimType: "guestReported",
                    title: "Street noise context is incomplete",
                    explanation: "Several guests mention late-night street noise.",
                    frequency: 10
                ),
                QualitySignal(
                    id: "high_less_frequent",
                    category: "checkInReliability",
                    severity: .high,
                    claimType: "guestReported",
                    title: "Guests report lockbox confusion",
                    explanation: "Recent guests could not find the lockbox after dark.",
                    frequency: 4
                )
            ]
        )
        let viewModel = HostDashboardViewModel(
            repository: StubListingRepository(stream: [snapshot(for: report)])
        )

        viewModel.load()
        try await Task.sleep(nanoseconds: 10_000_000)

        guard case let .loaded(data) = viewModel.state else {
            Issue.record("Expected loaded dashboard data.")
            return
        }

        #expect(data.primaryInsight?.signalId == "high_less_frequent")
        #expect(data.primaryInsight?.severity == .high)
    }

    @MainActor
    @Test func completeRecommendationOptimisticallyUpdatesLoadedState() async throws {
        let recommendation = Recommendation(
            id: "rec_checkin_photos_001",
            listingId: "stay_1001",
            title: "Add photo-based arrival instructions",
            hostAction: "Upload entrance and lockbox photos.",
            expectedImpact: "Reduce guest-reported check-in issues.",
            confidenceLevel: "high",
            claimType: "inferred",
            status: .suggested,
            priorityScore: 94,
            evidenceSignalIds: ["sig_checkin_001"]
        )
        let report = Self.makeQualityReport(recommendations: [recommendation])
        let repository = StubListingRepository(stream: [snapshot(for: report)])
        let viewModel = HostDashboardViewModel(repository: repository)

        viewModel.load()
        try await Task.sleep(nanoseconds: 10_000_000)
        await viewModel.completeRecommendation(id: "rec_checkin_photos_001")

        #expect(repository.completedRecommendationID == "rec_checkin_photos_001")

        guard case let .loaded(data) = viewModel.state else {
            Issue.record("Expected loaded dashboard data.")
            return
        }

        #expect(data.qualityReport.recommendations.first?.status == .completed)
    }

    @MainActor
    private func snapshot(for report: QualityReport) -> DataSnapshot<Listing> {
        DataSnapshot(
            value: makeListing(report: report),
            source: .network,
            fetchedAt: Date(),
            isStale: false,
            isOfflineFallback: false,
            refreshError: nil
        )
    }

    @MainActor
    private func makeListing(report: QualityReport? = nil) -> Listing {
        Listing(
            id: "stay_1001",
            title: "Bright Mission Studio Near Transit",
            location: "Mission District, San Francisco",
            thumbnailURL: nil,
            host: nil,
            qualityReport: report ?? Self.makeQualityReport()
        )
    }

    @MainActor
    private static func makeQualityReport(
        riskSignals: [QualitySignal] = [
            QualitySignal(
                id: "sig_checkin_001",
                category: "checkInReliability",
                severity: .high,
                claimType: "guestReported",
                title: "Guests report lockbox confusion",
                explanation: "Four check-in complaints mention the lockbox location.",
                frequency: 4
            )
        ],
        recommendations: [Recommendation] = []
    ) -> QualityReport {
        QualityReport(
            overallScore: 84,
            cleanlinessScore: 91,
            accuracyScore: 86,
            communicationScore: 88,
            safetyScore: 90,
            accessibilityScore: 80,
            riskSignals: riskSignals,
            recommendations: recommendations
        )
    }
}

@MainActor
private final class StubListingRepository: ListingRepositoryProtocol {
    private let stream: [DataSnapshot<Listing>]
    private(set) var requestedPolicy: FetchPolicy?
    private(set) var completedRecommendationID: String?

    init(stream: [DataSnapshot<Listing>]) {
        self.stream = stream
    }

    func listings(policy: FetchPolicy) -> AsyncThrowingStream<DataSnapshot<[Listing]>, Error> {
        AsyncThrowingStream { continuation in
            continuation.finish()
        }
    }

    func listing(id: Listing.ID, policy: FetchPolicy) -> AsyncThrowingStream<DataSnapshot<Listing>, Error> {
        requestedPolicy = policy

        return AsyncThrowingStream { continuation in
            for snapshot in stream {
                continuation.yield(snapshot)
            }
            continuation.finish()
        }
    }

    func completeRecommendation(id: String) async throws {
        completedRecommendationID = id
    }
}

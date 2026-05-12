//
//  ListingRepositoryTests.swift
//  ListingLensTests
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import SwiftData
import Testing
@testable import ListingLens

struct ListingRepositoryTests {

    @MainActor
    @Test func staleWhileRefreshYieldsCachedListingsThenFreshListings() async throws {
        let container = try ModelContainer(
            for: CachedListing.self,
            CachedQualityReport.self,
            CachedRecommendationState.self,
            Host.self,
            Listing.self,
            QualityReport.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        context.insert(
            CachedListing(
                id: "cached_stay",
                title: "Cached Garden Room",
                location: "Seattle, WA",
                thumbnailURL: nil,
                fetchedAt: .distantPast
            )
        )
        try context.save()

        let repository = ListingRepository(
            apiService: MockAPIService(latencyNanoseconds: 0),
            modelContext: context
        )

        var snapshots: [DataSnapshot<[Listing]>] = []
        for try await snapshot in repository.listings(policy: .staleWhileRefresh) {
            snapshots.append(snapshot)
            if snapshots.count == 2 {
                break
            }
        }

        #expect(snapshots.count == 2)
        #expect(snapshots[0].source == .cache)
        #expect(snapshots[0].value.first?.title == "Cached Garden Room")
        #expect(snapshots[1].source == .network)
        #expect(snapshots[1].value.first?.title == "Bright Mission Studio Near Transit")

        let descriptor = FetchDescriptor<CachedListing>()
        let cachedListings = try context.fetch(descriptor)
        #expect(cachedListings.contains { $0.id == "stay_1001" })
    }

    @MainActor
    @Test func staleWhileRefreshYieldsEmptyCacheBeforeFreshListings() async throws {
        let container = try ModelContainer(
            for: CachedListing.self,
            CachedQualityReport.self,
            CachedRecommendationState.self,
            Host.self,
            Listing.self,
            QualityReport.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = ListingRepository(
            apiService: MockAPIService(latencyNanoseconds: 0),
            modelContext: container.mainContext
        )

        var snapshots: [DataSnapshot<[Listing]>] = []
        for try await snapshot in repository.listings(policy: .staleWhileRefresh) {
            snapshots.append(snapshot)
            if snapshots.count == 2 {
                break
            }
        }

        #expect(snapshots.count == 2)
        #expect(snapshots[0].source == .cache)
        #expect(snapshots[0].value.isEmpty)
        #expect(snapshots[1].source == .network)
        #expect(!snapshots[1].value.isEmpty)
    }

    @MainActor
    @Test func listingCacheOnlyReturnsCachedQualityReportAfterRefresh() async throws {
        let container = try Self.makeContainer()
        let refreshRepository = ListingRepository(
            apiService: MockAPIService(latencyNanoseconds: 0),
            modelContext: container.mainContext
        )

        for try await snapshot in refreshRepository.listing(id: "stay_1001", policy: .refresh) {
            #expect(snapshot.value.qualityReport?.overallScore == 84)
        }

        let cacheOnlyRepository = ListingRepository(
            apiService: MockAPIService(latencyNanoseconds: 0),
            modelContext: container.mainContext
        )

        var cachedSnapshots: [DataSnapshot<Listing>] = []
        for try await snapshot in cacheOnlyRepository.listing(id: "stay_1001", policy: .cacheOnly) {
            cachedSnapshots.append(snapshot)
        }

        #expect(cachedSnapshots.count == 1)
        #expect(cachedSnapshots[0].source == .cache)
        #expect(cachedSnapshots[0].value.qualityReport?.overallScore == 84)
        #expect(cachedSnapshots[0].value.qualityReport?.riskSignals.first?.id == "sig_checkin_001")
    }

    @MainActor
    @Test func completedRecommendationStateSurvivesFreshRefresh() async throws {
        let container = try Self.makeContainer()
        let repository = ListingRepository(
            apiService: MockAPIService(latencyNanoseconds: 0),
            modelContext: container.mainContext
        )

        for try await _ in repository.listing(id: "stay_1001", policy: .refresh) {}
        try await repository.completeRecommendation(id: "rec_checkin_photos_001")

        var refreshedSnapshots: [DataSnapshot<Listing>] = []
        for try await snapshot in repository.listing(id: "stay_1001", policy: .refresh) {
            refreshedSnapshots.append(snapshot)
        }

        let recommendation = refreshedSnapshots
            .last?
            .value
            .qualityReport?
            .recommendations
            .first { $0.id == "rec_checkin_photos_001" }

        #expect(recommendation?.status == .completed)
    }

    private static func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: CachedListing.self,
            CachedQualityReport.self,
            CachedRecommendationState.self,
            Host.self,
            Listing.self,
            QualityReport.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }
}

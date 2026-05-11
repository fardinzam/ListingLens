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
}

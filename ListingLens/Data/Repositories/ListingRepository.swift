//
//  ListingRepository.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import SwiftData

enum FetchPolicy {
    case cacheOnly
    case refresh
    case staleWhileRefresh
}

enum DataSource: Equatable {
    case cache
    case network
}

struct DataSnapshot<Value> {
    let value: Value
    let source: DataSource
    let fetchedAt: Date?
    let isStale: Bool
    let isOfflineFallback: Bool
    let refreshError: Error?
}

protocol ListingRepositoryProtocol {
    func listings(policy: FetchPolicy) -> AsyncThrowingStream<DataSnapshot<[Listing]>, Error>
    func listing(id: Listing.ID, policy: FetchPolicy) -> AsyncThrowingStream<DataSnapshot<Listing>, Error>
    func completeRecommendation(id: String) async throws
}

@MainActor
final class ListingRepository: ListingRepositoryProtocol {
    private let apiService: MockAPIService
    private let modelContext: ModelContext

    init(apiService: MockAPIService, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
    }

    func listings(policy: FetchPolicy) -> AsyncThrowingStream<DataSnapshot<[Listing]>, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    let cachedListings = try fetchCachedListings()
                    if policy != .refresh {
                        yieldCachedListings(
                            cachedListings,
                            isStale: policy == .staleWhileRefresh,
                            isOfflineFallback: false,
                            refreshError: nil,
                            to: continuation
                        )
                    }

                    guard policy != .cacheOnly else {
                        continuation.finish()
                        return
                    }

                    continuation.yield(try await fetchFreshListingsSnapshot())
                    continuation.finish()
                } catch {
                    if finishWithOfflineFallback(policy: policy, error: error, continuation: continuation) {
                        return
                    }

                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func fetchFreshListingsSnapshot() async throws -> DataSnapshot<[Listing]> {
        let response: ListingIndexResponseDTO = try await apiService.fetch(endpoint: "/v1/listings")
        let freshListings = response.data.map { $0.toDomainModel() }
        try upsertCache(with: freshListings, fetchedAt: response.meta.fetchedAt)

        return DataSnapshot(
            value: freshListings,
            source: .network,
            fetchedAt: response.meta.fetchedAt,
            isStale: false,
            isOfflineFallback: false,
            refreshError: nil
        )
    }

    private func finishWithOfflineFallback(
        policy: FetchPolicy,
        error: Error,
        continuation: AsyncThrowingStream<DataSnapshot<[Listing]>, Error>.Continuation
    ) -> Bool {
        guard policy == .staleWhileRefresh else {
            return false
        }

        do {
            let cachedListings = try fetchCachedListings()
            guard !cachedListings.isEmpty else {
                return false
            }

            yieldCachedListings(
                cachedListings,
                isStale: true,
                isOfflineFallback: true,
                refreshError: error,
                to: continuation
            )
            continuation.finish()
            return true
        } catch {
            continuation.finish(throwing: error)
            return true
        }
    }

    private func yieldCachedListings(
        _ cachedListings: [CachedListing],
        isStale: Bool,
        isOfflineFallback: Bool,
        refreshError: Error?,
        to continuation: AsyncThrowingStream<DataSnapshot<[Listing]>, Error>.Continuation
    ) {
        continuation.yield(
            DataSnapshot(
                value: cachedListings.map { $0.toDomainModel() },
                source: .cache,
                fetchedAt: cachedListings.map(\.fetchedAt).max(),
                isStale: isStale,
                isOfflineFallback: isOfflineFallback,
                refreshError: refreshError
            )
        )
    }

    func listing(id: Listing.ID, policy: FetchPolicy) -> AsyncThrowingStream<DataSnapshot<Listing>, Error> {
        AsyncThrowingStream { continuation in
            let task = Task { @MainActor in
                do {
                    for try await snapshot in listings(policy: policy) {
                        if let listing = snapshot.value.first(where: { $0.id == id }) {
                            if snapshot.source == .network {
                                listing.qualityReport = try await fetchQualityReport(for: id)
                            }

                            continuation.yield(
                                DataSnapshot(
                                    value: listing,
                                    source: snapshot.source,
                                    fetchedAt: snapshot.fetchedAt,
                                    isStale: snapshot.isStale,
                                    isOfflineFallback: snapshot.isOfflineFallback,
                                    refreshError: snapshot.refreshError
                                )
                            )
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    func completeRecommendation(id: String) async throws {
        // Recommendation mutations are local-only for the MVP. The ViewModel
        // updates the visible state optimistically while this repository method
        // preserves the future API boundary for persisted mutation handling.
    }

    private func fetchCachedListings() throws -> [CachedListing] {
        let descriptor = FetchDescriptor<CachedListing>(
            sortBy: [SortDescriptor(\.title)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func upsertCache(with listings: [Listing], fetchedAt: Date) throws {
        let existingListings = try fetchCachedListings()
        for listing in listings {
            if let cachedListing = existingListings.first(where: { $0.id == listing.id }) {
                cachedListing.update(from: listing, fetchedAt: fetchedAt)
            } else {
                modelContext.insert(
                    CachedListing(
                        id: listing.id,
                        title: listing.title,
                        location: listing.location,
                        thumbnailURL: listing.thumbnailURL,
                        fetchedAt: fetchedAt
                    )
                )
            }
        }
        try modelContext.save()
    }

    private func fetchQualityReport(for listingID: Listing.ID) async throws -> QualityReport {
        let response: ListingQualityReportResponseDTO = try await apiService.fetch(
            endpoint: "/v1/listings/\(listingID)/quality-report"
        )
        return response.data.qualityReport.toDomainModel()
    }
}

private extension ListingSummaryDTO {
    func toDomainModel() -> Listing {
        Listing(
            id: id,
            title: title,
            location: locationSummary,
            thumbnailURL: thumbnailURL,
            host: Host(
                name: host.displayName,
                profileImageURL: nil,
                responseRate: 1.0,
                isSuperhost: host.isSuperhostLike
            ),
            qualityReport: QualityReport(
                overallScore: summary.overallScore,
                cleanlinessScore: summary.overallScore,
                accuracyScore: summary.overallScore,
                communicationScore: summary.overallScore,
                safetyScore: summary.overallScore,
                accessibilityScore: accessibilitySummary.completenessScore,
                reviewSentiments: [],
                trendDirection: TrendDirection(rawValue: summary.trendDirection) ?? .insufficientData
            )
        )
    }
}

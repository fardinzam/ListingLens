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
    private let qualityReportEncoder: JSONEncoder
    private let qualityReportDecoder: JSONDecoder

    init(apiService: MockAPIService, modelContext: ModelContext) {
        self.apiService = apiService
        self.modelContext = modelContext
        self.qualityReportEncoder = JSONEncoder()
        self.qualityReportDecoder = JSONDecoder()
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
                            } else {
                                listing.qualityReport = try cachedQualityReport(for: id)
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
        let listingID = try listingID(forRecommendation: id)
        let now = Date()

        if let cachedState = try cachedRecommendationState(for: id) {
            cachedState.status = .completed
            cachedState.updatedAt = now
        } else {
            modelContext.insert(
                CachedRecommendationState(
                    recommendationID: id,
                    listingID: listingID,
                    status: .completed,
                    updatedAt: now
                )
            )
        }

        try modelContext.save()
    }
}

private extension ListingRepository {
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
        let report = try mergeLocalRecommendationState(
            into: response.data.qualityReport.toDomainModel(),
            listingID: listingID
        )
        try upsertCachedQualityReport(
            report,
            listingID: listingID,
            fetchedAt: response.meta.generatedAt
        )
        return report
    }

    private func cachedQualityReport(for listingID: Listing.ID) throws -> QualityReport? {
        guard let cachedReport = try fetchCachedQualityReport(for: listingID),
              cachedReport.schemaVersion == CachedQualityReport.currentSchemaVersion else {
            return nil
        }

        let report = try cachedReport.toDomainModel(decoder: qualityReportDecoder)
        return try mergeLocalRecommendationState(into: report, listingID: listingID)
    }

    private func fetchCachedQualityReport(for listingID: Listing.ID) throws -> CachedQualityReport? {
        var descriptor = FetchDescriptor<CachedQualityReport>(
            predicate: #Predicate { $0.listingID == listingID }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func upsertCachedQualityReport(
        _ report: QualityReport,
        listingID: Listing.ID,
        fetchedAt: Date
    ) throws {
        let payload = try qualityReportEncoder.encode(report)
        let expiresAt = fetchedAt.addingTimeInterval(30 * 60)

        if let cachedReport = try fetchCachedQualityReport(for: listingID) {
            cachedReport.update(payload: payload, fetchedAt: fetchedAt, expiresAt: expiresAt)
        } else {
            modelContext.insert(
                CachedQualityReport(
                    listingID: listingID,
                    payload: payload,
                    fetchedAt: fetchedAt,
                    expiresAt: expiresAt
                )
            )
        }

        try modelContext.save()
    }

    private func mergeLocalRecommendationState(
        into report: QualityReport,
        listingID: Listing.ID
    ) throws -> QualityReport {
        let states = try fetchCachedRecommendationStates(for: listingID)
        guard !states.isEmpty else {
            return report
        }

        let statusByID = Dictionary(uniqueKeysWithValues: states.map { ($0.recommendationID, $0.status) })
        report.recommendations = report.recommendations.map { recommendation in
            var mergedRecommendation = recommendation
            if let localStatus = statusByID[recommendation.id] {
                mergedRecommendation.status = localStatus
            }
            return mergedRecommendation
        }
        return report
    }

    private func fetchCachedRecommendationStates(for listingID: Listing.ID) throws -> [CachedRecommendationState] {
        let descriptor = FetchDescriptor<CachedRecommendationState>(
            predicate: #Predicate { $0.listingID == listingID }
        )
        return try modelContext.fetch(descriptor)
    }

    private func cachedRecommendationState(
        for recommendationID: Recommendation.ID
    ) throws -> CachedRecommendationState? {
        var descriptor = FetchDescriptor<CachedRecommendationState>(
            predicate: #Predicate { $0.recommendationID == recommendationID }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func listingID(forRecommendation recommendationID: Recommendation.ID) throws -> Listing.ID {
        if let cachedState = try cachedRecommendationState(for: recommendationID) {
            return cachedState.listingID
        }

        let reports = try modelContext.fetch(FetchDescriptor<CachedQualityReport>())
        for cachedReport in reports where cachedReport.schemaVersion == CachedQualityReport.currentSchemaVersion {
            let report = try cachedReport.toDomainModel(decoder: qualityReportDecoder)
            if report.recommendations.contains(where: { $0.id == recommendationID }) {
                return cachedReport.listingID
            }
        }

        throw ListingRepositoryError.recommendationNotFound(recommendationID)
    }
}

enum ListingRepositoryError: Error, Equatable {
    case recommendationNotFound(String)
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

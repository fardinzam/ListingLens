//
//  HostDashboardViewModel.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import Observation

struct HostDashboardData {
    let listing: Listing
    let qualityReport: QualityReport
    let primaryInsight: PrimaryInsight?
}

struct PrimaryInsight: Equatable {
    let title: String
    let explanation: String
    let severity: SignalSeverity
    let signalId: String
}

@MainActor
@Observable
final class HostDashboardViewModel {
    enum State {
        case idle
        case loading
        case loaded(HostDashboardData)
        case failed(Error)
    }

    private(set) var state: State = .idle
    private(set) var showsStaleDataBanner = false

    private let listingID: Listing.ID
    private let repository: ListingRepositoryProtocol
    private var loadTask: Task<Void, Never>?

    init(listingID: Listing.ID = "stay_1001", repository: ListingRepositoryProtocol) {
        self.listingID = listingID
        self.repository = repository
    }

    func load() {
        loadTask?.cancel()
        state = .loading
        showsStaleDataBanner = false

        loadTask = Task { [repository, listingID] in
            do {
                for try await snapshot in repository.listing(id: listingID, policy: .staleWhileRefresh) {
                    try Task.checkCancellation()
                    guard let qualityReport = snapshot.value.qualityReport else {
                        continue
                    }

                    showsStaleDataBanner = snapshot.isStale
                    state = .loaded(
                        HostDashboardData(
                            listing: snapshot.value,
                            qualityReport: qualityReport,
                            primaryInsight: primaryInsight(from: qualityReport)
                        )
                    )
                }
            } catch is CancellationError {
                return
            } catch {
                showsStaleDataBanner = false
                state = .failed(error)
            }
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
    }

    func completeRecommendation(id: String) async {
        guard case let .loaded(currentData) = state else {
            return
        }

        let previousRecommendations = currentData.qualityReport.recommendations
        currentData.qualityReport.recommendations = previousRecommendations.map { recommendation in
            guard recommendation.id == id else {
                return recommendation
            }

            var completedRecommendation = recommendation
            completedRecommendation.status = .completed
            return completedRecommendation
        }

        state = .loaded(
            HostDashboardData(
                listing: currentData.listing,
                qualityReport: currentData.qualityReport,
                primaryInsight: currentData.primaryInsight
            )
        )

        do {
            try await repository.completeRecommendation(id: id)
        } catch {
            currentData.qualityReport.recommendations = previousRecommendations
            state = .failed(error)
        }
    }

    private func primaryInsight(from report: QualityReport) -> PrimaryInsight? {
        report.riskSignals
            .sorted { lhs, rhs in
                let lhsPriority = priority(for: lhs.severity)
                let rhsPriority = priority(for: rhs.severity)

                if lhsPriority == rhsPriority {
                    return lhs.frequency > rhs.frequency
                }

                return lhsPriority > rhsPriority
            }
            .first
            .map {
                PrimaryInsight(
                    title: $0.title,
                    explanation: $0.explanation,
                    severity: $0.severity,
                    signalId: $0.id
                )
            }
    }

    private func priority(for severity: SignalSeverity) -> Int {
        switch severity {
        case .critical:
            4
        case .high:
            3
        case .medium:
            2
        case .low:
            1
        }
    }
}

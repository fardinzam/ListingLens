//
//  GuestTrustViewModel.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import Observation

struct TrustSummary {
    let listing: Listing
    let qualityReport: QualityReport
    let strongestPositiveSignal: QualitySignal?
    let primaryCaution: QualitySignal?
}

@MainActor
@Observable
final class GuestTrustViewModel {
    enum State {
        case idle
        case loading
        case loaded(TrustSummary)
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

        loadTask = Task { [listingID, repository] in
            do {
                for try await snapshot in repository.listing(id: listingID, policy: .staleWhileRefresh) {
                    try Task.checkCancellation()
                    guard let report = snapshot.value.qualityReport else {
                        continue
                    }

                    showsStaleDataBanner = snapshot.isStale
                    state = .loaded(summary(for: snapshot.value, report: report))
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

    private func summary(for listing: Listing, report: QualityReport) -> TrustSummary {
        TrustSummary(
            listing: listing,
            qualityReport: report,
            strongestPositiveSignal: strongestPositiveSignal(from: report),
            primaryCaution: primaryCaution(from: report)
        )
    }

    private func strongestPositiveSignal(from report: QualityReport) -> QualitySignal? {
        report.positiveSignals.sorted { lhs, rhs in
            lhs.frequency > rhs.frequency
        }.first
    }

    private func primaryCaution(from report: QualityReport) -> QualitySignal? {
        report.riskSignals.sorted { lhs, rhs in
            let lhsPriority = priority(for: lhs.severity)
            let rhsPriority = priority(for: rhs.severity)

            if lhsPriority == rhsPriority {
                return lhs.frequency > rhs.frequency
            }

            return lhsPriority > rhsPriority
        }.first
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

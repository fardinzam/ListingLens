//
//  QualityReportDetailViewModel.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class QualityReportDetailViewModel {
    enum State {
        case idle
        case loading
        case loaded(GraphQLListingQualityDetailsResponseDTO)
        case failed(Error)
    }

    private(set) var state: State = .idle

    private let listingID: Listing.ID
    private let graphQLService: MockGraphQLService
    private var loadTask: Task<Void, Never>?

    init(listingID: Listing.ID = "stay_1001", graphQLService: MockGraphQLService) {
        self.listingID = listingID
        self.graphQLService = graphQLService
    }

    func load() {
        loadTask?.cancel()
        state = .loading

        loadTask = Task { [graphQLService, listingID] in
            do {
                let response = try await graphQLService.listingQualityDetails(listingID: listingID)
                state = .loaded(response)
            } catch is CancellationError {
                return
            } catch {
                state = .failed(error)
            }
        }
    }
}

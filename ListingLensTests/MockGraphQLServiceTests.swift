//
//  MockGraphQLServiceTests.swift
//  ListingLensTests
//
//  Created by Fardin Zaman on 5/11/26.
//

import Testing
@testable import ListingLens

struct MockGraphQLServiceTests {

    @MainActor
    @Test func listingQualityDetailsDecodes404FixtureAsAPIError() async {
        let service = MockGraphQLService(latencyNanoseconds: 0)

        await #expect(throws: MockAPIServiceError.apiError(
            statusCode: 404,
            code: "listing_quality_details_not_found",
            message: "ListingQualityDetails could not find listing stay_missing.",
            requestId: "mock_req_404_graphql_listing_quality_details"
        )) {
            _ = try await service.listingQualityDetails(listingID: "stay_missing")
        }
    }
}

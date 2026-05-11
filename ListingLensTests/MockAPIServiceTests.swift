//
//  MockAPIServiceTests.swift
//  ListingLensTests
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import Testing
@testable import ListingLens

struct MockAPIServiceTests {

    @MainActor
    @Test func fetchDecodesListingIndexFixture() async throws {
        let service = MockAPIService(latencyNanoseconds: 0)

        let response: ListingIndexResponseDTO = try await service.fetch(endpoint: "/v1/listings")

        #expect(response.data.count == 1)
        #expect(response.data.first?.title == "Bright Mission Studio Near Transit")
        #expect(response.data.first?.host.displayName == "Maya")
        #expect(response.data.first?.summary.overallScore == 84)
        #expect(response.meta.fixtureName == "listings.index.json")
    }

    @MainActor
    @Test func fetchThrowsForMissingFixture() async {
        let service = MockAPIService(latencyNanoseconds: 0)

        await #expect(throws: MockAPIServiceError.self) {
            let _: ListingIndexResponseDTO = try await service.fetch(endpoint: "/v1/unknown")
        }
    }
}

//
//  MockGraphQLService.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

final class MockGraphQLService {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let latencyNanoseconds: UInt64

    init(
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder(),
        latencyNanoseconds: UInt64 = 1_000_000_000
    ) {
        self.bundle = bundle
        self.decoder = decoder
        self.decoder.dateDecodingStrategy = .iso8601
        self.latencyNanoseconds = latencyNanoseconds
    }

    func listingQualityDetails(listingID: Listing.ID) async throws -> GraphQLListingQualityDetailsResponseDTO {
        try await Task.sleep(nanoseconds: latencyNanoseconds)

        let resourceName = "graphql.listing_quality_details.\(listingID)"
        guard let fixture = fixture(for: resourceName) else {
            throw MockAPIServiceError.fixtureNotFound(endpoint: "ListingQualityDetails", resourceName: resourceName)
        }

        do {
            let data = try Data(contentsOf: fixture.url)
            if let errorResponse = try? decoder.decode(APIErrorResponseDTO.self, from: data) {
                throw MockAPIServiceError.apiError(
                    statusCode: statusCode(for: fixture.resourceName),
                    code: errorResponse.error.code,
                    message: errorResponse.error.message,
                    requestId: errorResponse.error.requestId
                )
            }
            return try decoder.decode(GraphQLListingQualityDetailsResponseDTO.self, from: data)
        } catch let error as DecodingError {
            throw MockAPIServiceError.decodingFailed(endpoint: "ListingQualityDetails", underlying: error)
        } catch let error as MockAPIServiceError {
            throw error
        } catch {
            throw MockAPIServiceError.loadingFailed(endpoint: "ListingQualityDetails", underlying: error)
        }
    }

    private func fixture(for resourceName: String) -> (url: URL, resourceName: String)? {
        for candidate in [resourceName, "\(resourceName).404"] {
            if let url = fixtureURL(for: candidate) {
                return (url, candidate)
            }
        }

        return nil
    }

    private func fixtureURL(for resourceName: String) -> URL? {
        bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources/MockAPI") ??
            bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "MockAPI") ??
            bundle.url(forResource: resourceName, withExtension: "json")
    }

    private func statusCode(for resourceName: String) -> Int {
        resourceName
            .split(separator: ".")
            .compactMap { Int($0) }
            .first { 100..<600 ~= $0 } ?? 500
    }
}

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

        #expect(response.data.count == 2)
        #expect(response.data.first?.title == "Bright Mission Studio Near Transit")
        #expect(response.data.first?.host.displayName == "Maya")
        #expect(response.data.first?.summary.overallScore == 84)
        #expect(response.meta.fixtureName == "listings.index.json")
    }

    @MainActor
    @Test func fetchDecodesQualityReportFixture() async throws {
        let service = MockAPIService(latencyNanoseconds: 0)

        let response: ListingQualityReportResponseDTO = try await service.fetch(
            endpoint: "/v1/listings/stay_1001/quality-report"
        )

        #expect(response.data.listing.id == "stay_1001")
        #expect(response.data.qualityReport.overallScore == 84)
        #expect(response.data.qualityReport.riskSignals.first?.id == "sig_checkin_001")
        #expect(response.data.qualityReport.recommendations.first?.id == "rec_checkin_photos_001")
    }

    @MainActor
    @Test func fetchThrowsForMissingFixture() async {
        let service = MockAPIService(latencyNanoseconds: 0)

        await #expect(throws: MockAPIServiceError.self) {
            let _: ListingIndexResponseDTO = try await service.fetch(endpoint: "/v1/unknown")
        }
    }

    @MainActor
    @Test func fetchDecodesQualityReport404FixtureAsAPIError() async {
        let service = MockAPIService(latencyNanoseconds: 0)

        await #expect(throws: MockAPIServiceError.apiError(
            statusCode: 404,
            code: "quality_report_not_found",
            message: "No quality report exists for listing stay_missing.",
            requestId: "mock_req_404_quality_report"
        )) {
            let _: ListingQualityReportResponseDTO = try await service.fetch(
                endpoint: "/v1/listings/stay_missing/quality-report"
            )
        }
    }

    @MainActor
    @Test func fetchCanForceQualityReport500FixtureAsAPIError() async {
        let service = MockAPIService(
            latencyNanoseconds: 0,
            fixtureOverrides: [
                "/v1/listings/stay_1001/quality-report": "listings.stay_1001.quality_report.500"
            ]
        )

        await #expect(throws: MockAPIServiceError.apiError(
            statusCode: 500,
            code: "quality_report_refresh_failed",
            message: "The mock quality report service failed while refreshing listing stay_1001.",
            requestId: "mock_req_500_quality_report"
        )) {
            let _: ListingQualityReportResponseDTO = try await service.fetch(
                endpoint: "/v1/listings/stay_1001/quality-report"
            )
        }
    }

    @MainActor
    @Test func fetchCanForceRecommendation500FixtureAsAPIError() async {
        let service = MockAPIService(
            latencyNanoseconds: 0,
            fixtureOverrides: [
                "/v1/recommendations/interventions": "recommendations.interventions.500"
            ]
        )

        await #expect(throws: MockAPIServiceError.apiError(
            statusCode: 500,
            code: "recommendation_engine_failure",
            message: "The mock recommendation engine failed while generating interventions.",
            requestId: "mock_req_500_recommendation"
        )) {
            let _: ListingQualityReportResponseDTO = try await service.fetch(
                endpoint: "/v1/recommendations/interventions"
            )
        }
    }
}

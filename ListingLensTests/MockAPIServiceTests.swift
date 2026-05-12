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
    @Test func fetchDecodesHostReputationFixture() async throws {
        let service = MockAPIService(latencyNanoseconds: 0)

        let response: HostReputationResponseDTO = try await service.fetch(
            endpoint: "/v1/hosts/host_501/reputation"
        )

        #expect(response.data.host.displayName == "Maya")
        #expect(response.data.reputation.metrics.responseRate == 0.98)
        #expect(response.data.reputation.riskSignals.first?.claimType == "guestReported")
        #expect(response.meta.fixtureName == "hosts.host_501.reputation.json")
    }

    @MainActor
    @Test func fetchDecodesRecommendationSuggestFixture() async throws {
        let service = MockAPIService(latencyNanoseconds: 0)

        let response: RecommendationInterventionResponseDTO = try await service.fetch(
            endpoint: "/v1/recommendations/interventions"
        )

        #expect(response.data.action == "suggest")
        #expect(response.data.recommendations?.count == 2)
        #expect(response.data.recommendations?.first?.id == "rec_checkin_photos_001")
    }

    @MainActor
    @Test func fetchCanForceRecommendationDismissFixture() async throws {
        let service = MockAPIService(
            latencyNanoseconds: 0,
            fixtureOverrides: [
                "/v1/recommendations/interventions": "recommendations.interventions.dismiss.success"
            ]
        )

        let response: RecommendationInterventionResponseDTO = try await service.fetch(
            endpoint: "/v1/recommendations/interventions"
        )

        #expect(response.data.action == "dismiss")
        #expect(response.data.recommendation?.status == .dismissed)
        #expect(response.data.recommendation?.id == "rec_checkin_photos_001")
    }

    @MainActor
    @Test func fetchCanForceInvalidSignalPayloadFixtureAsAPIError() async {
        let service = MockAPIService(
            latencyNanoseconds: 0,
            fixtureOverrides: [
                "/v1/quality/signals": "errors.invalid_signal_payload"
            ]
        )

        await #expect(throws: MockAPIServiceError.apiError(
            statusCode: 422,
            code: "invalid_signal_payload",
            message: "Signal payload is missing required fields.",
            requestId: "mock_req_422_create_signal"
        )) {
            let _: APIErrorResponseDTO = try await service.fetch(endpoint: "/v1/quality/signals")
        }
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

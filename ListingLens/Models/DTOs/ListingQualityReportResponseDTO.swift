//
//  ListingQualityReportResponseDTO.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

struct ListingQualityReportResponseDTO: Decodable, Equatable {
    let data: ListingQualityReportDataDTO
    let meta: QualityReportMetaDTO
}

struct ListingQualityReportDataDTO: Decodable, Equatable {
    let listing: QualityReportListingDTO
    let qualityReport: QualityReportDTO
}

struct QualityReportListingDTO: Decodable, Equatable {
    let id: String
    let title: String
    let locationSummary: String
    let hostId: String
}

struct QualityReportDTO: Decodable, Equatable {
    let id: String
    let listingId: String
    let overallScore: Int
    let confidenceLevel: String
    let dataCompleteness: Double
    let trend: QualityTrendDTO
    let scoreBreakdown: [CategoryScoreDTO]
    let riskSignals: [QualitySignalDTO]
    let positiveSignals: [QualitySignalDTO]
    let aiSignals: AISignalsDTO
    let accessibility: AccessibilityDetailDTO
    let recommendations: [RecommendationDTO]
}

struct QualityTrendDTO: Decodable, Equatable {
    let direction: TrendDirection
    let delta30Days: Int
    let summary: String
}

struct CategoryScoreDTO: Decodable, Equatable {
    let category: String
    let label: String
    let score: Int
    let weight: Double
    let weightedContribution: Double
    let confidenceLevel: String
    let dataCompleteness: Double
    let evidenceCount: Int
    let explanation: String
}

struct QualitySignalDTO: Decodable, Equatable {
    let id: String
    let category: String
    let severity: SignalSeverity
    let claimType: String
    let title: String
    let explanation: String
    let frequency: Int
}

struct AISignalsDTO: Decodable, Equatable {
    let themes: [ReviewThemeDTO]
}

struct ReviewThemeDTO: Decodable, Equatable {
    let label: String
    let sentiment: SentimentPolarity
}

struct RecommendationDTO: Decodable, Equatable {
    let id: String
    let listingId: String
    let title: String
    let hostAction: String
    let expectedImpact: String
    let confidenceLevel: String
    let claimType: String
    let status: RecommendationStatus
    let priorityScore: Int
    let evidenceSignalIds: [String]
}

struct AccessibilityDetailDTO: Decodable, Equatable {
    let claimType: String
    let completenessScore: Int
    let features: AccessibilityFeaturesDTO
}

struct AccessibilityFeaturesDTO: Decodable, Equatable {
    let stepFreeAccess: AccessibilityFeatureDTO
    let elevator: AccessibilityFeatureDTO
    let wideDoorways: AccessibilityFeatureDTO
    let accessibleParking: AccessibilityFeatureDTO
    let stepFreeShower: AccessibilityFeatureDTO
    let captionsOnMedia: AccessibilityFeatureDTO
    let serviceAnimalPolicyClarity: AccessibilityFeatureDTO
}

struct AccessibilityFeatureDTO: Decodable, Equatable {
    let available: Bool
    let claimType: String
    let details: String
}

struct QualityReportMetaDTO: Decodable, Equatable {
    let fixtureName: String
    let requestId: String
    let generatedAt: Date
}

extension QualityReportDTO {
    func toDomainModel() -> QualityReport {
        QualityReport(
            overallScore: overallScore,
            cleanlinessScore: score(for: "cleanliness"),
            accuracyScore: score(for: "accuracy"),
            communicationScore: score(for: "communication"),
            safetyScore: score(for: "safetySignals"),
            accessibilityScore: score(for: "accessibilityCompleteness"),
            reviewSentiments: aiSignals.themes.map {
                ReviewSentiment(theme: $0.label, polarity: $0.sentiment)
            },
            riskSignals: riskSignals.map { $0.toDomainModel() },
            positiveSignals: positiveSignals.map { $0.toDomainModel() },
            recommendations: recommendations.map { $0.toDomainModel() },
            trendDirection: trend.direction,
            accessibilityFeatures: accessibility.toDomainModel()
        )
    }

    private func score(for category: String) -> Int {
        scoreBreakdown.first { $0.category == category }?.score ?? 0
    }
}

private extension AccessibilityDetailDTO {
    func toDomainModel() -> [AccessibilityFeature] {
        [
            features.stepFreeAccess.toDomainModel(name: "Step-free access"),
            features.elevator.toDomainModel(name: "Elevator"),
            features.wideDoorways.toDomainModel(name: "Wide doorways"),
            features.accessibleParking.toDomainModel(name: "Accessible parking"),
            features.stepFreeShower.toDomainModel(name: "Step-free shower"),
            features.captionsOnMedia.toDomainModel(name: "Captions on media"),
            features.serviceAnimalPolicyClarity.toDomainModel(name: "Service animal policy")
        ]
    }
}

private extension AccessibilityFeatureDTO {
    func toDomainModel(name: String) -> AccessibilityFeature {
        AccessibilityFeature(
            name: name,
            isAvailable: available,
            claimType: claimType,
            details: details
        )
    }
}

private extension QualitySignalDTO {
    func toDomainModel() -> QualitySignal {
        QualitySignal(
            id: id,
            category: category,
            severity: severity,
            claimType: claimType,
            title: title,
            explanation: explanation,
            frequency: frequency
        )
    }
}

private extension RecommendationDTO {
    func toDomainModel() -> Recommendation {
        Recommendation(
            id: id,
            listingId: listingId,
            title: title,
            hostAction: hostAction,
            expectedImpact: expectedImpact,
            confidenceLevel: confidenceLevel,
            claimType: claimType,
            status: status,
            priorityScore: priorityScore,
            evidenceSignalIds: evidenceSignalIds
        )
    }
}

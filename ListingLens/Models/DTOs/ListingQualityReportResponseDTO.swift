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
    let scoreBreakdown: [CategoryScoreDTO]
    let riskSignals: [QualitySignalDTO]
    let positiveSignals: [QualitySignalDTO]
    let aiSignals: AISignalsDTO
    let recommendations: [RecommendationDTO]
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
            recommendations: recommendations.map { $0.toDomainModel() }
        )
    }

    private func score(for category: String) -> Int {
        scoreBreakdown.first { $0.category == category }?.score ?? 0
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

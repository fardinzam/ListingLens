//
//  RecommendationInterventionResponseDTO.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/12/26.
//

import Foundation

struct RecommendationInterventionResponseDTO: Decodable, Equatable {
    let data: RecommendationInterventionDataDTO
    let meta: RecommendationInterventionMetaDTO
}

struct RecommendationInterventionDataDTO: Decodable, Equatable {
    let listingId: String
    let action: String
    let recommendations: [RecommendationInterventionDTO]?
    let recommendation: DismissedRecommendationDTO?
}

struct RecommendationInterventionDTO: Decodable, Equatable {
    let id: String
    let listingId: String
    let title: String
    let hostAction: String
    let expectedImpact: String
    let confidenceLevel: String
    let claimType: String
    let status: RecommendationStatus
    let priorityScore: Int
    let rankingFactors: RecommendationRankingFactorsDTO
    let evidenceSignalIds: [String]
    let evidence: [RecommendationEvidenceDTO]
    let createdAt: Date
    let updatedAt: Date
}

struct RecommendationRankingFactorsDTO: Decodable, Equatable {
    let severity: SignalSeverity
    let frequency: Int
    let recencyDays: Int
    let expectedImpact: String
}

struct RecommendationEvidenceDTO: Decodable, Equatable {
    let id: String
    let type: String
    let summary: String
}

struct DismissedRecommendationDTO: Decodable, Equatable {
    let id: String
    let status: RecommendationStatus
    let dismissedAt: Date
    let dismissReason: String
}

struct RecommendationInterventionMetaDTO: Decodable, Equatable {
    let fixtureName: String
    let requestId: String
    let fetchedAt: Date
}

//
//  ListingIndexResponseDTO.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

struct ListingIndexResponseDTO: Decodable, Equatable {
    let data: [ListingSummaryDTO]
    let meta: ListingIndexMetaDTO
}

struct ListingSummaryDTO: Decodable, Equatable {
    let id: String
    let title: String
    let locationSummary: String
    let thumbnailURL: URL?
    let host: ListingHostSummaryDTO
    let summary: ListingQualitySummaryDTO
    let badges: [QualityBadgeDTO]
    let accessibilitySummary: AccessibilitySummaryDTO
    let updatedAt: Date
}

struct ListingHostSummaryDTO: Decodable, Equatable {
    let id: String
    let displayName: String
    let isSuperhostLike: Bool
    let responseTimeMinutes: Int
}

struct ListingQualitySummaryDTO: Decodable, Equatable {
    let overallScore: Int
    let confidenceLevel: String
    let dataCompleteness: Double
    let trendDirection: String
    let primaryInsight: PrimaryInsightDTO
}

struct PrimaryInsightDTO: Decodable, Equatable {
    let title: String
    let description: String
    let severity: String
    let claimType: String
}

struct QualityBadgeDTO: Decodable, Equatable {
    let id: String
    let label: String
    let explanation: String
    let claimType: String
}

struct AccessibilitySummaryDTO: Decodable, Equatable {
    let completenessScore: Int
    let claimType: String
    let stepFreeAccess: Bool
    let elevator: Bool
    let wideDoorways: Bool?
}

struct ListingIndexMetaDTO: Decodable, Equatable {
    let count: Int
    let fetchedAt: Date
    let fixtureName: String
}

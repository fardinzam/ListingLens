//
//  GraphQLListingQualityDetailsDTO.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

struct GraphQLListingQualityDetailsResponseDTO: Decodable, Equatable {
    let data: GraphQLListingQualityDetailsDataDTO
}

struct GraphQLListingQualityDetailsDataDTO: Decodable, Equatable {
    let listing: GraphQLListingQualityDetailsListingDTO
}

struct GraphQLListingQualityDetailsListingDTO: Decodable, Equatable {
    let id: String
    let title: String
    let qualityReport: GraphQLQualityReportDTO
}

struct GraphQLQualityReportDTO: Decodable, Equatable {
    let overallScore: Int
    let confidenceLevel: String
    let dataCompleteness: Double
    let scoreBreakdown: [GraphQLCategoryScoreDTO]
    let riskSignals: [GraphQLSignalDTO]
    let positiveSignals: [GraphQLSignalDTO]
}

struct GraphQLCategoryScoreDTO: Decodable, Equatable, Identifiable {
    var id: String { category }

    let category: String
    let score: Int
    let weight: Double
    let weightedContribution: Double
    let confidenceLevel: String
    let dataCompleteness: Double
    let explanation: String
}

struct GraphQLSignalDTO: Decodable, Equatable, Identifiable {
    let id: String
    let category: String
    let severity: SignalSeverity?
    let claimType: String
    let title: String
    let explanation: String
}

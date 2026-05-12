//
//  HostReputationResponseDTO.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/12/26.
//

import Foundation

struct HostReputationResponseDTO: Decodable, Equatable {
    let data: HostReputationDataDTO
    let meta: HostReputationMetaDTO
}

struct HostReputationDataDTO: Decodable, Equatable {
    let host: HostReputationHostDTO
    let reputation: HostReputationDTO
}

struct HostReputationHostDTO: Decodable, Equatable {
    let id: String
    let displayName: String
    let joinedAt: Date
    let activeListingIds: [String]
}

struct HostReputationDTO: Decodable, Equatable {
    let overallScore: Int
    let confidenceLevel: String
    let dataCompleteness: Double
    let claimType: String
    let summary: String
    let metrics: HostReputationMetricsDTO
    let history: [HostReputationHistoryDTO]
    let positiveSignals: [HostReputationSignalDTO]
    let riskSignals: [HostReputationSignalDTO]
}

struct HostReputationMetricsDTO: Decodable, Equatable {
    let medianResponseTimeMinutes: Int
    let responseRate: Double
    let hostInitiatedCancellationRate: Double
    let resolvedIssueRate: Double
    let averageRating: Double
    let reviewCount: Int
}

struct HostReputationHistoryDTO: Decodable, Equatable {
    let period: String
    let overallScore: Int
    let guestReportedIssueCount: Int
    let hostInitiatedCancellations: Int
}

struct HostReputationSignalDTO: Decodable, Equatable {
    let id: String
    let category: String
    let title: String
    let explanation: String
    let severity: SignalSeverity?
    let claimType: String
}

struct HostReputationMetaDTO: Decodable, Equatable {
    let fixtureName: String
    let fetchedAt: Date
}

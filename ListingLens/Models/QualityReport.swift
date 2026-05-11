//
//  QualityReport.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import SwiftData

@Model
final class QualityReport: Decodable {
    var overallScore: Int
    var cleanlinessScore: Int
    var accuracyScore: Int
    var communicationScore: Int
    var safetyScore: Int
    var accessibilityScore: Int
    var reviewSentiments: [ReviewSentiment]
    var riskSignals: [QualitySignal]
    var positiveSignals: [QualitySignal]
    var recommendations: [Recommendation]

    init(
        overallScore: Int,
        cleanlinessScore: Int,
        accuracyScore: Int,
        communicationScore: Int,
        safetyScore: Int,
        accessibilityScore: Int,
        reviewSentiments: [ReviewSentiment] = [],
        riskSignals: [QualitySignal] = [],
        positiveSignals: [QualitySignal] = [],
        recommendations: [Recommendation] = []
    ) {
        self.overallScore = overallScore
        self.cleanlinessScore = cleanlinessScore
        self.accuracyScore = accuracyScore
        self.communicationScore = communicationScore
        self.safetyScore = safetyScore
        self.accessibilityScore = accessibilityScore
        self.reviewSentiments = reviewSentiments
        self.riskSignals = riskSignals
        self.positiveSignals = positiveSignals
        self.recommendations = recommendations
    }

    private enum CodingKeys: String, CodingKey {
        case overallScore
        case cleanlinessScore
        case accuracyScore
        case communicationScore
        case safetyScore
        case accessibilityScore
        case reviewSentiments
        case riskSignals
        case positiveSignals
        case recommendations
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let overallScore = try container.decode(Int.self, forKey: .overallScore)
        let cleanlinessScore = try container.decode(Int.self, forKey: .cleanlinessScore)
        let accuracyScore = try container.decode(Int.self, forKey: .accuracyScore)
        let communicationScore = try container.decode(Int.self, forKey: .communicationScore)
        let safetyScore = try container.decode(Int.self, forKey: .safetyScore)
        let accessibilityScore = try container.decode(Int.self, forKey: .accessibilityScore)
        let reviewSentiments = try container.decodeIfPresent([ReviewSentiment].self, forKey: .reviewSentiments) ?? []
        let riskSignals = try container.decodeIfPresent([QualitySignal].self, forKey: .riskSignals) ?? []
        let positiveSignals = try container.decodeIfPresent([QualitySignal].self, forKey: .positiveSignals) ?? []
        let recommendations = try container.decodeIfPresent([Recommendation].self, forKey: .recommendations) ?? []

        self.init(
            overallScore: overallScore,
            cleanlinessScore: cleanlinessScore,
            accuracyScore: accuracyScore,
            communicationScore: communicationScore,
            safetyScore: safetyScore,
            accessibilityScore: accessibilityScore,
            reviewSentiments: reviewSentiments,
            riskSignals: riskSignals,
            positiveSignals: positiveSignals,
            recommendations: recommendations
        )
    }
}

struct QualitySignal: Codable, Hashable, Identifiable {
    let id: String
    let category: String
    let severity: SignalSeverity
    let claimType: String
    let title: String
    let explanation: String
    let frequency: Int
}

enum SignalSeverity: String, Codable, Hashable {
    case low
    case medium
    case high
    case critical
}

struct Recommendation: Codable, Hashable, Identifiable {
    let id: String
    let listingId: String
    let title: String
    let hostAction: String
    let expectedImpact: String
    let confidenceLevel: String
    let claimType: String
    var status: RecommendationStatus
    let priorityScore: Int
    let evidenceSignalIds: [String]
}

enum RecommendationStatus: String, Codable, Hashable {
    case suggested
    case dismissed
    case completed
}

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

    init(
        overallScore: Int,
        cleanlinessScore: Int,
        accuracyScore: Int,
        communicationScore: Int,
        safetyScore: Int,
        accessibilityScore: Int,
        reviewSentiments: [ReviewSentiment] = []
    ) {
        self.overallScore = overallScore
        self.cleanlinessScore = cleanlinessScore
        self.accuracyScore = accuracyScore
        self.communicationScore = communicationScore
        self.safetyScore = safetyScore
        self.accessibilityScore = accessibilityScore
        self.reviewSentiments = reviewSentiments
    }

    private enum CodingKeys: String, CodingKey {
        case overallScore
        case cleanlinessScore
        case accuracyScore
        case communicationScore
        case safetyScore
        case accessibilityScore
        case reviewSentiments
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

        self.init(
            overallScore: overallScore,
            cleanlinessScore: cleanlinessScore,
            accuracyScore: accuracyScore,
            communicationScore: communicationScore,
            safetyScore: safetyScore,
            accessibilityScore: accessibilityScore,
            reviewSentiments: reviewSentiments
        )
    }
}

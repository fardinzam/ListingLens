//
//  QualityScore.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

struct QualityScore: Decodable, Hashable {
    nonisolated static let safetyWeight = 1.0
    nonisolated static let cleanlinessWeight = 0.8
    nonisolated static let accuracyWeight = 0.7
    nonisolated static let communicationWeight = 0.7
    nonisolated static let accessibilityWeight = 0.6

    let cleanliness: Int
    let accuracy: Int
    let communication: Int
    let safety: Int
    let accessibility: Int
}

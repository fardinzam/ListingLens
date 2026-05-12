//
//  CachedRecommendationState.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/12/26.
//

import Foundation
import SwiftData

@Model
final class CachedRecommendationState {
    @Attribute(.unique) var recommendationID: String
    var listingID: String
    var statusRawValue: String
    var updatedAt: Date

    var status: RecommendationStatus {
        get {
            RecommendationStatus(rawValue: statusRawValue) ?? .suggested
        }
        set {
            statusRawValue = newValue.rawValue
        }
    }

    init(
        recommendationID: String,
        listingID: String,
        status: RecommendationStatus,
        updatedAt: Date
    ) {
        self.recommendationID = recommendationID
        self.listingID = listingID
        self.statusRawValue = status.rawValue
        self.updatedAt = updatedAt
    }
}

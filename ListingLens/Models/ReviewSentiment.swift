//
//  ReviewSentiment.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

struct ReviewSentiment: Codable, Hashable {
    let theme: String
    let polarity: SentimentPolarity
}

enum SentimentPolarity: String, Codable, Hashable {
    case positive
    case neutral
    case negative
}

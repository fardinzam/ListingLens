//
//  ListingLensTests.swift
//  ListingLensTests
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import Testing
@testable import ListingLens

struct ListingLensTests {

    @MainActor
    @Test func decodesListingWithNestedHostAndQualityReport() async throws {
        let json = """
        {
          "title": "Bright Mission Studio Near Transit",
          "location": "Mission District, San Francisco",
          "thumbnailURL": "https://example.com/listing.jpg",
          "host": {
            "name": "Maya",
            "profileImageURL": "https://example.com/maya.jpg",
            "responseRate": 0.98,
            "isSuperhost": true
          },
          "qualityReport": {
            "overallScore": 84,
            "cleanlinessScore": 91,
            "accuracyScore": 86,
            "communicationScore": 88,
            "safetyScore": 90,
            "accessibilityScore": 80,
            "reviewSentiments": [
              {
                "theme": "Easy check-in",
                "polarity": "positive"
              },
              {
                "theme": "Noisy",
                "polarity": "negative"
              }
            ]
          }
        }
        """

        let listing = try JSONDecoder().decode(Listing.self, from: Data(json.utf8))

        #expect(listing.title == "Bright Mission Studio Near Transit")
        #expect(listing.location == "Mission District, San Francisco")
        #expect(listing.thumbnailURL?.absoluteString == "https://example.com/listing.jpg")
        #expect(listing.host?.name == "Maya")
        #expect(listing.host?.profileImageURL?.absoluteString == "https://example.com/maya.jpg")
        #expect(listing.host?.responseRate == 0.98)
        #expect(listing.host?.isSuperhost == true)
        #expect(listing.qualityReport?.overallScore == 84)
        #expect(listing.qualityReport?.cleanlinessScore == 91)
        #expect(listing.qualityReport?.accuracyScore == 86)
        #expect(listing.qualityReport?.communicationScore == 88)
        #expect(listing.qualityReport?.safetyScore == 90)
        #expect(listing.qualityReport?.accessibilityScore == 80)
        #expect(listing.qualityReport?.reviewSentiments.first?.theme == "Easy check-in")
        #expect(listing.qualityReport?.reviewSentiments.first?.polarity == .positive)
        #expect(QualityScore.safetyWeight == 1.0)
        #expect(QualityScore.cleanlinessWeight == 0.8)
    }

}

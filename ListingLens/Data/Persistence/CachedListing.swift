//
//  CachedListing.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import SwiftData

@Model
final class CachedListing {
    @Attribute(.unique) var id: String
    var title: String
    var location: String
    var thumbnailURL: URL?
    var fetchedAt: Date

    init(
        id: String,
        title: String,
        location: String,
        thumbnailURL: URL? = nil,
        fetchedAt: Date
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.thumbnailURL = thumbnailURL
        self.fetchedAt = fetchedAt
    }

    func toDomainModel() -> Listing {
        Listing(
            id: id,
            title: title,
            location: location,
            thumbnailURL: thumbnailURL
        )
    }

    func update(from listing: Listing, fetchedAt: Date) {
        title = listing.title
        location = listing.location
        thumbnailURL = listing.thumbnailURL
        self.fetchedAt = fetchedAt
    }
}

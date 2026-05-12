//
//  CachedQualityReport.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/12/26.
//

import Foundation
import SwiftData

@Model
final class CachedQualityReport {
    static let currentSchemaVersion = 1

    @Attribute(.unique) var listingID: String
    var payload: Data
    var fetchedAt: Date
    var expiresAt: Date
    var schemaVersion: Int

    init(
        listingID: String,
        payload: Data,
        fetchedAt: Date,
        expiresAt: Date,
        schemaVersion: Int = CachedQualityReport.currentSchemaVersion
    ) {
        self.listingID = listingID
        self.payload = payload
        self.fetchedAt = fetchedAt
        self.expiresAt = expiresAt
        self.schemaVersion = schemaVersion
    }

    func toDomainModel(decoder: JSONDecoder = JSONDecoder()) throws -> QualityReport {
        try decoder.decode(QualityReport.self, from: payload)
    }

    func update(payload: Data, fetchedAt: Date, expiresAt: Date) {
        self.payload = payload
        self.fetchedAt = fetchedAt
        self.expiresAt = expiresAt
        schemaVersion = Self.currentSchemaVersion
    }
}

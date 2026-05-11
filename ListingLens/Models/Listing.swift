//
//  Listing.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import SwiftData

@Model
final class Listing: Decodable, Identifiable {
    @Attribute(.unique) var id: String
    var title: String
    var location: String
    var thumbnailURL: URL?
    @Relationship(deleteRule: .nullify) var host: Host?
    @Relationship(deleteRule: .cascade) var qualityReport: QualityReport?

    init(
        id: String = UUID().uuidString,
        title: String,
        location: String,
        thumbnailURL: URL? = nil,
        host: Host? = nil,
        qualityReport: QualityReport? = nil
    ) {
        self.id = id
        self.title = title
        self.location = location
        self.thumbnailURL = thumbnailURL
        self.host = host
        self.qualityReport = qualityReport
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case location
        case thumbnailURL
        case host
        case qualityReport
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        let title = try container.decode(String.self, forKey: .title)
        let location = try container.decode(String.self, forKey: .location)
        let thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnailURL)
        let host = try container.decodeIfPresent(Host.self, forKey: .host)
        let qualityReport = try container.decodeIfPresent(QualityReport.self, forKey: .qualityReport)

        self.init(
            id: id,
            title: title,
            location: location,
            thumbnailURL: thumbnailURL,
            host: host,
            qualityReport: qualityReport
        )
    }
}

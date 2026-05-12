//
//  Host.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation
import SwiftData

@Model
final class Host: Decodable {
    var id: String?
    var name: String
    var profileImageURL: URL?
    var responseRate: Double
    var isSuperhost: Bool
    var joinedAt: Date?
    var activeListingIds: [String]

    init(
        id: String? = nil,
        name: String,
        profileImageURL: URL? = nil,
        responseRate: Double,
        isSuperhost: Bool,
        joinedAt: Date? = nil,
        activeListingIds: [String] = []
    ) {
        self.id = id
        self.name = name
        self.profileImageURL = profileImageURL
        self.responseRate = responseRate
        self.isSuperhost = isSuperhost
        self.joinedAt = joinedAt
        self.activeListingIds = activeListingIds
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case displayName
        case profileImageURL
        case responseRate
        case isSuperhost
        case joinedAt
        case activeListingIds
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(String.self, forKey: .id)
        let name = try container.decodeIfPresent(String.self, forKey: .name) ??
            container.decode(String.self, forKey: .displayName)
        let profileImageURL = try container.decodeIfPresent(URL.self, forKey: .profileImageURL)
        let responseRate = try container.decodeIfPresent(Double.self, forKey: .responseRate) ?? 0
        let isSuperhost = try container.decodeIfPresent(Bool.self, forKey: .isSuperhost) ?? false
        let joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt)
        let activeListingIds = try container.decodeIfPresent([String].self, forKey: .activeListingIds) ?? []

        self.init(
            id: id,
            name: name,
            profileImageURL: profileImageURL,
            responseRate: responseRate,
            isSuperhost: isSuperhost,
            joinedAt: joinedAt,
            activeListingIds: activeListingIds
        )
    }
}

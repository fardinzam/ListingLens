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
    var name: String
    var profileImageURL: URL?
    var responseRate: Double
    var isSuperhost: Bool

    init(
        name: String,
        profileImageURL: URL? = nil,
        responseRate: Double,
        isSuperhost: Bool
    ) {
        self.name = name
        self.profileImageURL = profileImageURL
        self.responseRate = responseRate
        self.isSuperhost = isSuperhost
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case profileImageURL
        case responseRate
        case isSuperhost
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let profileImageURL = try container.decodeIfPresent(URL.self, forKey: .profileImageURL)
        let responseRate = try container.decode(Double.self, forKey: .responseRate)
        let isSuperhost = try container.decode(Bool.self, forKey: .isSuperhost)

        self.init(
            name: name,
            profileImageURL: profileImageURL,
            responseRate: responseRate,
            isSuperhost: isSuperhost
        )
    }
}

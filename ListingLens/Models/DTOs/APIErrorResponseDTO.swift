//
//  APIErrorResponseDTO.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

struct APIErrorResponseDTO: Decodable, Equatable {
    let error: APIErrorDTO
}

struct APIErrorDTO: Decodable, Equatable {
    let code: String
    let message: String
    let requestId: String?
    let retryable: Bool
}

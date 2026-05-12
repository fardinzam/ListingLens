//
//  MockAPIService.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import Foundation

final class MockAPIService {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let latencyNanoseconds: UInt64
    private let fixtureOverrides: [String: String]

    init(
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder(),
        latencyNanoseconds: UInt64 = 1_000_000_000,
        fixtureOverrides: [String: String] = [:]
    ) {
        self.bundle = bundle
        self.decoder = decoder
        self.decoder.dateDecodingStrategy = .iso8601
        self.latencyNanoseconds = latencyNanoseconds
        self.fixtureOverrides = fixtureOverrides
    }

    func fetch<T: Decodable>(endpoint: String) async throws -> T {
        try await Task.sleep(nanoseconds: latencyNanoseconds)

        let resourceName = fixtureOverrides[endpoint] ?? resourceName(for: endpoint)
        guard let fixture = fixture(for: resourceName) else {
            throw MockAPIServiceError.fixtureNotFound(endpoint: endpoint, resourceName: resourceName)
        }

        do {
            let data = try Data(contentsOf: fixture.url)
            if let errorResponse = try? decoder.decode(APIErrorResponseDTO.self, from: data) {
                throw MockAPIServiceError.apiError(
                    statusCode: statusCode(for: fixture.resourceName),
                    code: errorResponse.error.code,
                    message: errorResponse.error.message,
                    requestId: errorResponse.error.requestId
                )
            }
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw MockAPIServiceError.decodingFailed(endpoint: endpoint, underlying: error)
        } catch let error as MockAPIServiceError {
            throw error
        } catch {
            throw MockAPIServiceError.loadingFailed(endpoint: endpoint, underlying: error)
        }
    }

    private func fixture(for resourceName: String) -> (url: URL, resourceName: String)? {
        for candidate in [resourceName, "\(resourceName).404"] {
            if let url = fixtureURL(for: candidate) {
                return (url, candidate)
            }
        }

        return nil
    }

    private func fixtureURL(for resourceName: String) -> URL? {
        bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "Resources/MockAPI") ??
            bundle.url(forResource: resourceName, withExtension: "json", subdirectory: "MockAPI") ??
            bundle.url(forResource: resourceName, withExtension: "json")
    }

    private func statusCode(for resourceName: String) -> Int {
        resourceName
            .split(separator: ".")
            .compactMap { Int($0) }
            .first { 100..<600 ~= $0 } ?? 500
    }

    private func resourceName(for endpoint: String) -> String {
        let normalizedEndpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = normalizedEndpoint.hasPrefix("v1/")
            ? String(normalizedEndpoint.dropFirst(3))
            : normalizedEndpoint
        let components = path.split(separator: "/").map(String.init)

        if components == ["listings"] {
            return "listings.index"
        }

        if components.count == 3, components[0] == "listings", components[2] == "quality-report" {
            return "listings.\(components[1]).quality_report"
        }

        if components.count == 3, components[0] == "hosts", components[2] == "reputation" {
            return "hosts.\(components[1]).reputation"
        }

        switch components {
        case ["quality", "signals"]:
            return "quality.signals.create.success"
        case ["recommendations", "interventions"]:
            return "recommendations.interventions.suggest.success"
        default:
            return normalizedEndpoint
                .replacingOccurrences(of: "/", with: ".")
                .replacingOccurrences(of: "-", with: "_")
        }
    }
}

enum MockAPIServiceError: Error, Equatable {
    case fixtureNotFound(endpoint: String, resourceName: String)
    case apiError(statusCode: Int, code: String, message: String, requestId: String?)
    case loadingFailed(endpoint: String, underlyingDescription: String)
    case decodingFailed(endpoint: String, underlyingDescription: String)

    static func loadingFailed(endpoint: String, underlying: Error) -> MockAPIServiceError {
        .loadingFailed(endpoint: endpoint, underlyingDescription: String(describing: underlying))
    }

    static func decodingFailed(endpoint: String, underlying: DecodingError) -> MockAPIServiceError {
        .decodingFailed(endpoint: endpoint, underlyingDescription: String(describing: underlying))
    }
}

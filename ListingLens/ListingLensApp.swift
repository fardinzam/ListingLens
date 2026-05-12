//
//  ListingLensApp.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI
import SwiftData

@main
struct ListingLensApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Host.self,
            Listing.self,
            QualityReport.self,
            CachedListing.self,
            CachedQualityReport.self,
            CachedRecommendationState.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

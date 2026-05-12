//
//  ContentView.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            HostDashboardView(repository: repository)
                .tabItem {
                    Label("Host", systemImage: "person.crop.circle.badge.checkmark")
                }

            GuestTrustView(
                repository: repository,
                graphQLService: MockGraphQLService()
            )
            .tabItem {
                Label("Guest", systemImage: "shield.checkered")
            }
        }
    }

    private var repository: ListingRepository {
        ListingRepository(
            apiService: MockAPIService(),
            modelContext: modelContext
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [
                Item.self,
                Host.self,
                Listing.self,
                QualityReport.self,
                CachedListing.self
            ],
            inMemory: true
        )
}

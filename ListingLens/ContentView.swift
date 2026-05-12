//
//  ContentView.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    private enum Persona: String {
        case host
        case guest
    }

    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedPersona") private var selectedPersona = Persona.host.rawValue

    init() {
        if ProcessInfo.processInfo.arguments.contains("--reset-selected-persona") {
            UserDefaults.standard.removeObject(forKey: "selectedPersona")
        }
    }

    var body: some View {
        TabView(selection: $selectedPersona) {
            HostDashboardView(repository: repository)
                .tabItem {
                    Label("Host", systemImage: "person.crop.circle.badge.checkmark")
                }
                .tag(Persona.host.rawValue)

            GuestTrustView(
                repository: repository,
                graphQLService: MockGraphQLService()
            )
            .tabItem {
                Label("Guest", systemImage: "shield.checkered")
            }
            .tag(Persona.guest.rawValue)
        }
        .accessibilityIdentifier("persona-tabs")
    }

    private var repository: ListingRepository {
        ListingRepository(
            apiService: MockAPIService(latencyNanoseconds: apiLatencyNanoseconds),
            modelContext: modelContext
        )
    }

    private var apiLatencyNanoseconds: UInt64 {
        ProcessInfo.processInfo.arguments.contains("--ui-testing") ? 0 : 1_000_000_000
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
                CachedListing.self,
                CachedQualityReport.self,
                CachedRecommendationState.self
            ],
            inMemory: true
        )
}

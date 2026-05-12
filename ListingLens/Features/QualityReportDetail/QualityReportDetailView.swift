//
//  QualityReportDetailView.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct QualityReportDetailView: View {
    @State private var viewModel: QualityReportDetailViewModel

    init(viewModel: QualityReportDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                loadingView
            case let .loaded(response):
                detail(response.data.listing)
            case let .failed(error):
                failedView(error)
            }
        }
        .navigationTitle("Quality Report")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if case .idle = viewModel.state {
                viewModel.load()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading GraphQL quality details")
                .font(.headline)
        }
        .padding()
    }

    private func failedView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Could not load report", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                viewModel.load()
            }
        }
    }

    private func detail(_ listing: GraphQLListingQualityDetailsListingDTO) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(listing)
                scoreCard(listing.qualityReport)
                breakdown(listing.qualityReport.scoreBreakdown)
                signals(
                    risks: listing.qualityReport.riskSignals,
                    positives: listing.qualityReport.positiveSignals
                )
            }
            .padding(20)
        }
        .accessibilityIdentifier("quality-report-detail")
        .background(Color(.systemGroupedBackground))
    }

    private func header(_ listing: GraphQLListingQualityDetailsListingDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SignalBadge(text: "GraphQL Fixture", systemImage: "curlybraces", tint: .blue)
            Text(listing.title)
                .font(.title.weight(.bold))
            Text("ListingQualityDetails query preserves evidence, claim type, and weighted category data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func scoreCard(_ report: GraphQLQualityReportDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(report.overallScore) / 100")
                .font(.largeTitle.weight(.bold))
            SignalBadge(
                text: "\(report.confidenceLevel.capitalized) Confidence",
                systemImage: "checkmark.seal",
                tint: .green
            )
            Text("Data completeness: \(Int(report.dataCompleteness * 100))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func breakdown(_ scores: [GraphQLCategoryScoreDTO]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Score Breakdown", detail: "Weighted contribution from the GraphQL response")

            ForEach(scores) { score in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(label(for: score.category))
                            .font(.headline)
                        Spacer()
                        Text("\(score.score)")
                            .font(.headline)
                    }
                    Text(score.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private func signals(risks: [GraphQLSignalDTO], positives: [GraphQLSignalDTO]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Risk and Positive Signals", detail: "Claim type is preserved for each signal")

            ForEach(risks) { signal in
                signalCard(signal, tint: .orange, icon: "exclamationmark.triangle.fill")
            }

            ForEach(positives) { signal in
                signalCard(signal, tint: .green, icon: "checkmark.seal.fill")
            }
        }
    }

    private func signalCard(_ signal: GraphQLSignalDTO, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SignalBadge(text: claimLabel(signal.claimType), systemImage: icon, tint: tint)
            Text(signal.title)
                .font(.headline)
            Text(signal.explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionHeader(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func label(for category: String) -> String {
        switch category {
        case "checkInReliability":
            "Check-in reliability"
        case "cleanliness":
            "Cleanliness"
        default:
            category
        }
    }

    private func claimLabel(_ claimType: String) -> String {
        switch claimType {
        case "verified":
            "Verified"
        case "hostProvided":
            "Host Provided"
        case "guestReported":
            "Guest Reported"
        case "inferred":
            "Inferred"
        default:
            "Claim Unknown"
        }
    }
}

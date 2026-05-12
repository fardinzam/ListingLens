//
//  HostDashboardView.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct HostDashboardView: View {
    @State private var viewModel: HostDashboardViewModel

    init(viewModel: HostDashboardViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    init(repository: ListingRepositoryProtocol) {
        self.init(viewModel: HostDashboardViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case let .loaded(data):
                    dashboard(data)
                case let .failed(error):
                    failedView(error)
                }
            }
            .navigationTitle("Host Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if case .idle = viewModel.state {
                    viewModel.load()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading quality signals")
                .font(.headline)
            Text("ListingLens is preparing the host dashboard.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func failedView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Could not load dashboard", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                viewModel.load()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func dashboard(_ data: HostDashboardData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(data)

                QualityScoreCard(
                    score: data.qualityReport.overallScore,
                    trend: data.qualityReport.trendDirection
                )

                InsightCard(
                    insight: data.primaryInsight,
                    actionTitle: primaryActionTitle(for: data)
                ) {
                    Task {
                        await completePrimaryRecommendation(in: data)
                    }
                }

                recommendationsSection(data.qualityReport.recommendations)
                scoreBreakdownSection(data.qualityReport)
                reviewThemesSection(data.qualityReport.reviewSentiments)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            viewModel.load()
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.showsStaleDataBanner {
                StaleDataBanner()
                    .padding(.bottom, 8)
            }
        }
    }

    private func header(_ data: HostDashboardData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(data.listing.title)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Label(data.listing.location, systemImage: "mappin.and.ellipse")

                if viewModel.showsStaleDataBanner {
                    Text("Last updated from cache")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func recommendationsSection(_ recommendations: [Recommendation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recommended Actions", detail: "Evidence-grounded steps for this listing")

            if recommendations.isEmpty {
                emptyCard("No open recommendations right now.")
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendations) { recommendation in
                        RecommendationCard(recommendation: recommendation) {
                            Task {
                                await viewModel.completeRecommendation(id: recommendation.id)
                            }
                        }
                    }
                }
            }
        }
    }

    private func scoreBreakdownSection(_ report: QualityReport) -> some View {
        GroupBox {
            VStack(spacing: 14) {
                scoreRow("Cleanliness", score: report.cleanlinessScore, systemImage: "sparkles")
                scoreRow("Accuracy", score: report.accuracyScore, systemImage: "checkmark.seal")
                scoreRow("Communication", score: report.communicationScore, systemImage: "message")
                scoreRow("Safety", score: report.safetyScore, systemImage: "shield.lefthalf.filled")
                scoreRow("Accessibility", score: report.accessibilityScore, systemImage: "figure.roll")
            }
        } label: {
            sectionHeader("Score Breakdown", detail: "Weighted quality categories")
        }
    }

    private func reviewThemesSection(_ sentiments: [ReviewSentiment]) -> some View {
        GroupBox {
            if sentiments.isEmpty {
                emptyCard("Review themes will appear after the quality report refreshes.")
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(sentiments, id: \.self) { sentiment in
                        SignalBadge(
                            text: sentiment.theme,
                            systemImage: icon(for: sentiment.polarity),
                            tint: color(for: sentiment.polarity)
                        )
                    }
                }
            }
        } label: {
            sectionHeader("Review Themes", detail: "Extracted from guest feedback")
        }
    }

    private func scoreRow(_ title: String, score: Int, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Gauge(value: Double(min(max(score, 0), 100)), in: 0...100) {
                Text(title)
            } currentValueLabel: {
                Text("\(score)")
                    .font(.caption.weight(.bold))
            }
            .labelsHidden()
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(scoreColor(score))
        }
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

    private func emptyCard(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func primaryActionTitle(for data: HostDashboardData) -> String {
        data.qualityReport.recommendations.first?.title ?? "Review quality details"
    }

    private func completePrimaryRecommendation(in data: HostDashboardData) async {
        guard let recommendation = data.qualityReport.recommendations.first else {
            return
        }

        await viewModel.completeRecommendation(id: recommendation.id)
    }

    private func icon(for polarity: SentimentPolarity) -> String {
        switch polarity {
        case .positive:
            "hand.thumbsup.fill"
        case .neutral:
            "minus.circle.fill"
        case .negative:
            "exclamationmark.triangle.fill"
        }
    }

    private func color(for polarity: SentimentPolarity) -> Color {
        switch polarity {
        case .positive:
            .green
        case .neutral:
            .blue
        case .negative:
            .orange
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 85...100:
            .green
        case 70..<85:
            .orange
        default:
            .red
        }
    }
}

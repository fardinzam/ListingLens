//
//  GuestTrustView.swift
//  ListingLens
//
//  Created by Fardin Zaman on 5/11/26.
//

import SwiftUI

struct GuestTrustView: View {
    @State private var viewModel: GuestTrustViewModel
    private let graphQLService: MockGraphQLService

    init(viewModel: GuestTrustViewModel, graphQLService: MockGraphQLService) {
        _viewModel = State(initialValue: viewModel)
        self.graphQLService = graphQLService
    }

    init(repository: ListingRepositoryProtocol, graphQLService: MockGraphQLService) {
        self.init(
            viewModel: GuestTrustViewModel(repository: repository),
            graphQLService: graphQLService
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    loadingView
                case let .loaded(summary):
                    trustDashboard(summary)
                case let .failed(error):
                    failedView(error)
                }
            }
            .navigationTitle("Guest Trust")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if case .idle = viewModel.state {
                    viewModel.load()
                }
            }
        }
    }
}

private extension GuestTrustView {
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading trust signals")
                .font(.headline)
            Text("ListingLens is checking quality and claim metadata.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func failedView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Could not load guest trust", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again") {
                viewModel.load()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func trustDashboard(_ summary: TrustSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(summary.listing)
                trustHero(summary)
                reliabilitySection(summary)
                accessibilitySection(summary.qualityReport)
                reviewThemesSection(summary.qualityReport.reviewSentiments)

                NavigationLink {
                    QualityReportDetailView(
                        viewModel: QualityReportDetailViewModel(
                            listingID: summary.listing.id,
                            graphQLService: graphQLService
                        )
                    )
                } label: {
                    Label("View Full Quality Report", systemImage: "doc.text.magnifyingglass")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("view-full-quality-report")
            }
            .padding(20)
        }
        .accessibilityIdentifier("guest-trust")
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

    private func header(_ listing: Listing) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(listing.title)
                .font(.largeTitle.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)

            Label(listing.location, systemImage: "mappin.and.ellipse")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func trustHero(_ summary: TrustSummary) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SignalBadge(
                text: claimLabel(summary.primaryCaution?.claimType),
                systemImage: "exclamationmark.triangle.fill",
                tint: .orange
            )

            Text("Strong stay quality with check-in caution")
                .font(.title3.weight(.bold))

            Text(heroCopy(summary))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                if let positive = summary.strongestPositiveSignal {
                    signalBadge(for: positive, fallbackIcon: "checkmark.seal.fill", tint: .green)
                }

                if let caution = summary.primaryCaution {
                    signalBadge(for: caution, fallbackIcon: "exclamationmark.triangle.fill", tint: .orange)
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
    }

    private func reliabilitySection(_ summary: TrustSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Reliability Indicators", detail: "Signals guests can act on before booking")

            reliabilityCard(
                title: "Check-in Reliability",
                badge: claimLabel(summary.primaryCaution?.claimType),
                icon: "key.fill",
                tint: .orange,
                body: summary.primaryCaution?.explanation ?? "No recent check-in issues detected."
            )

            reliabilityCard(
                title: "Host Responsiveness",
                badge: "Verified",
                icon: "message.fill",
                tint: .green,
                body: "Median response time is under one hour across recent guest messages."
            )
        }
    }

    private func reliabilityCard(
        title: String,
        badge: String,
        icon: String,
        tint: Color,
        body: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                SignalBadge(text: badge, systemImage: icon, tint: tint)
            }

            Text(body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
    }

    private func accessibilitySection(_ report: QualityReport) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Accessibility Highlights", detail: "Host-provided details, not verified compliance")

            VStack(alignment: .leading, spacing: 12) {
                FlowLayout(spacing: 8) {
                    ForEach(report.accessibilityFeatures.filter(\.isAvailable)) { feature in
                        SignalBadge(
                            text: feature.name,
                            systemImage: "info.circle.fill",
                            tint: .blue
                        )
                    }
                }

                Text("Accessibility details are labeled Host Provided so guests understand they are self-reported.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.quaternary)
            }
        }
    }

    private func reviewThemesSection(_ sentiments: [ReviewSentiment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("What Guests Love", detail: "AI-generated review themes")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sentiments.filter { $0.polarity == .positive }, id: \.self) { sentiment in
                        SignalBadge(
                            text: sentiment.theme,
                            systemImage: "heart.fill",
                            tint: .green
                        )
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func signalBadge(for signal: QualitySignal, fallbackIcon: String, tint: Color) -> some View {
        SignalBadge(
            text: signal.title,
            systemImage: fallbackIcon,
            tint: tint
        )
        .accessibilityHint("Claim type: \(claimLabel(signal.claimType))")
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

    private func heroCopy(_ summary: TrustSummary) -> String {
        let positive = summary.strongestPositiveSignal?.title ?? "Guests mention reliable stay quality"
        let caution = summary.primaryCaution?.title ?? "No major caution signal"
        return """
        \(positive). \(caution). Claim badges preserve whether signals are verified, \
        host-provided, or guest-reported.
        """
    }

    private func claimLabel(_ claimType: String?) -> String {
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

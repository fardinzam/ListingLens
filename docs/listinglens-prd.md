# ListingLens PRD

Status: Draft for portfolio implementation  
Target role: Airbnb Software Engineer, New Grad - Quality Reputation  
Project name: ListingLens  
MVP decisions: bundled JSON/mock data layer, iOS 17 Observation, iPhone-only.

## 1. Product Summary

ListingLens is an iOS portfolio app that helps hosts and guests understand stay quality before and after a booking. The app models a simplified version of a quality reputation system: it collects quality signals from listing metadata, reviews, guest reports, host responsiveness, check-in history, accessibility completeness, and cancellation behavior, then turns those signals into actionable quality insights.

The product has two distinct personas:

- Hosts use the app to identify quality risks, understand guest feedback trends, and act on prioritized improvement recommendations.
- Guests use the app to evaluate listing trust, reliability, accessibility readiness, and potential trip friction before booking.

The project is designed to map directly to Airbnb's Quality Reputation team: customer-facing quality products, reputation systems, proactive intervention, high-quality supply, user protection, cross-functional product thinking, Swift/iOS execution, and foundational AI-powered experiences.

## 2. Goals

### Product Goals

- Help hosts discover and address the highest-impact quality issues before they lead to poor guest experiences.
- Help guests make more confident booking decisions using clear, explainable trust and quality signals.
- Demonstrate how quality signals can elevate strong supply while flagging risky or incomplete listings.
- Provide an AI-assisted recommendation experience that is useful, explainable, and grounded in visible evidence.
- Present quality information with progressive disclosure so users see the most important insight first and can drill into supporting evidence when needed.

### Portfolio Goals

- Demonstrate Swift, SwiftUI, MVVM, async programming, networking, caching, client storage, accessibility, REST, and GraphQL.
- Show systems thinking through quality scoring, signal weighting, intervention prioritization, and privacy/fairness tradeoffs.
- Show product judgment through focused MVP scope, defined success metrics, and explicit out-of-scope decisions.
- Show leadership/mentorship through strong documentation, contributor onboarding, architecture notes, and technical decision records.

## 3. Non-Goals

- This is not a booking app.
- This is not a full Airbnb clone.
- This is not a production moderation, enforcement, or fraud system.
- This is not a marketplace ranking engine.
- This is not a real-time messaging or support platform.
- This is not a fully trained ML system. AI/ML behavior may be simulated or implemented through a small, explainable recommendation layer.

## 4. Target Users

### Persona A: Host

The host wants to maintain a high-quality listing, avoid preventable guest issues, and understand what actions will most improve their reputation. They may have limited time and need clear prioritization.

Host motivations:

- Improve listing quality.
- Prevent recurring guest complaints.
- Protect ratings and reputation.
- Understand what guests are actually saying.
- Know which action to take next.

Host pain points:

- Reviews are noisy and hard to summarize.
- Some issues are only visible after repeated complaints.
- It is unclear which improvements matter most.
- Accessibility, check-in, and listing accuracy gaps can be easy to miss.

### Persona B: Guest

The guest wants to quickly understand whether a listing is reliable, accurate, and suitable for their needs. They need transparency without being overloaded by raw data or unsupported certainty.

Guest motivations:

- Avoid check-in problems, inaccurate listings, cleanliness issues, and unreliable hosts.
- Understand the difference between a highly rated listing and a consistently reliable listing.
- Find accessibility-relevant details quickly.
- Trust that quality badges are explainable.

Guest pain points:

- Average star ratings hide important patterns.
- Review text takes too long to scan.
- Accessibility information can be incomplete.
- Recent quality changes may not be obvious.

## 5. MVP Scope

The MVP should be completable quickly while still covering the job description's strongest signals.

### Required MVP Features

1. Host dashboard
   - Overall quality score.
   - Quality trend.
   - One primary insight derived from the highest-priority risk or recommendation.
   - Top risk signal and primary recommended action on the first screen.
   - Additional positive signals, risk signals, review themes, and score breakdowns behind drill-down sections.
   - Prioritized intervention list.
   - AI Quality Coach summary.

2. Guest trust view
   - Listing trust summary.
   - Host reputation summary.
   - Reliability indicators.
   - Review theme highlights.
   - Accessibility completeness summary.
   - Explanation for each quality badge.
   - Progressive disclosure so the first screen emphasizes the trust summary, check-in reliability, accessibility completeness, and one strongest positive or caution signal.

3. Listing quality report
   - Cleanliness score.
   - Accuracy score.
   - Check-in score.
   - Communication score.
   - Safety signal status.
   - Accessibility completeness score.
   - Recent review themes.

4. Quality scoring engine
   - Weighted, explainable score.
   - Deterministic local implementation.
   - Unit tested.
   - Inputs include review sentiment, cancellation rate, host response time, check-in issue rate, cleanliness reports, safety reports, and accessibility completeness.
   - Confidence and data completeness metadata for the overall score and category scores.
   - Clear labeling that MVP weights are heuristic and not statistically validated against production marketplace outcomes.

5. REST-shaped mock API
   - Bundled JSON fixtures with an injected mocking layer instead of a separate backend process.
   - Route-like request handlers for listings, hosts, quality reports, quality signals, and recommendations.
   - Artificial latency and failure modes for loading, stale-cache, and retry demos.

6. GraphQL query
   - One GraphQL query for listing quality details.
   - Used by one iOS screen to show practical exposure to GraphQL without overbuilding the backend.

7. Local persistence
   - Use SwiftData for structured cached listing reports and saved listings.
   - Use UserDefaults only for lightweight preferences such as onboarding completion, selected persona, and display settings.

8. Offline-aware caching
   - Show cached quality reports immediately.
   - Refresh in the background when network is available.
   - Display a clear offline or stale-data state.

9. Accessibility
   - VoiceOver labels for scores, badges, alerts, and chart summaries.
   - Dynamic Type support.
   - Status indicators that do not rely on color alone.
   - Accessible tap targets.

10. Testing and documentation
   - Unit tests for scoring logic.
   - Unit tests for cache freshness rules.
   - Unit tests for API client decoding and error handling.
   - README, architecture doc, API spec, and review notes for the application-ready MVP.
   - Contributor guide, first-good-issue list, and technical decision records as follow-up polish if time allows before submission.

## 6. Recommended Technical Choices

### Architecture

Use MVVM.

Rationale:

- It is familiar in SwiftUI projects.
- It separates presentation state from scoring, API, and persistence logic.
- It makes unit testing straightforward.
- It maps well to the role's expectations around maintainable iOS code.
- The MVP targets iOS 17, so ViewModels should use Swift Observation to reduce boilerplate while staying current with modern SwiftUI patterns.

Suggested layers:

- Views: SwiftUI screens and reusable UI components.
- ViewModels: screen state, async loading, error states, user actions.
- Services: API client, GraphQL client, quality scoring service, recommendation service.
- Persistence: SwiftData models and repositories.
- Domain models: Listing, Host, Review, QualitySignal, QualityReport, Recommendation.

### Local Storage

Choose SwiftData plus UserDefaults.

Rationale:

- SwiftData is the best fit for a modern, fast-to-build portfolio project if targeting iOS 17 or newer.
- Core Data is powerful but adds setup complexity that does not improve this portfolio project's signal enough.
- SQLite is unnecessary unless the project needs custom query control or cross-platform storage.
- UserDefaults is too limited for structured cached reports, but appropriate for simple preferences.

Storage plan:

- SwiftData: cached listings, quality reports, saved listings, dismissed interventions.
- UserDefaults: onboarding complete, selected persona, last active tab, developer mode toggle.

### API

Use bundled JSON fixtures with REST-shaped request handlers plus one GraphQL-shaped query fixture.

Rationale:

- This is the fastest path to a polished portfolio app because no separate server setup is required.
- The iOS app still exercises realistic API boundaries: typed clients, DTO decoding, async/await, cancellation, errors, and retries.
- Demo data remains deterministic, which makes screenshots, tests, and interview walkthroughs reliable.
- The mock layer can later be swapped for a real backend because repositories depend on client protocols rather than fixture files directly.

REST-shaped routes:

- `GET /v1/listings`
- `GET /v1/listings/{id}/quality-report`
- `GET /v1/hosts/{id}/reputation`
- `POST /v1/quality/signals`
- `POST /v1/recommendations/interventions`

GraphQL-shaped query:

```graphql
query ListingQualityDetails($listingId: ID!) {
  listing(id: $listingId) {
    id
    title
    qualityReport {
      overallScore
      confidenceLevel
      dataCompleteness
      scoreBreakdown {
        category
        score
        weight
        weightedContribution
        explanation
      }
      riskSignals {
        id
        category
        severity
        claimType
        title
        explanation
      }
      positiveSignals {
        id
        category
        claimType
        title
        explanation
      }
    }
  }
}
```

Use REST-shaped fixtures for most app flows and a GraphQL-shaped fixture for the detailed listing quality screen. This demonstrates REST and GraphQL data modeling without spending MVP time on backend infrastructure.

### AI Quality Coach

MVP implementation should use a deterministic recommendation adapter with seeded AI-style summaries. A real LLM integration can be added later behind the same interface.

Rationale:

- Faster to complete.
- Easier to test.
- Avoids API key and cost issues.
- Still demonstrates AI product thinking by grounding recommendations in visible signals.

Each recommendation must include:

- Recommendation title.
- Host action.
- Evidence signals.
- Expected impact.
- Confidence level.
- Claim type: verified, host-provided, guest-reported, or inferred.

Example:

- Title: Improve check-in clarity.
- Action: Add photo-based arrival instructions and mention the lockbox location earlier.
- Evidence: 4 check-in complaints in the last 30 days, 3 reviews mentioning "hard to find entrance."
- Expected impact: Reduce guest-reported check-in issues.
- Confidence: High.

## 7. User Stories

### Host User Stories

1. As a host, I want to see my overall listing quality score so that I can understand whether my listing is healthy at a glance.

Acceptance criteria:

- The dashboard displays a score from 0 to 100.
- The score has an accessible text explanation.
- The score shows whether it is improving, declining, or stable.

2. As a host, I want to see the top risk signals affecting my listing so that I can focus on the issues most likely to hurt guest experience.

Acceptance criteria:

- The dashboard shows at least three prioritized risk signals when available.
- Each signal includes severity, category, and explanation.
- The list is sorted by expected guest impact.

3. As a host, I want AI-generated improvement suggestions so that I can quickly decide what action to take next.

Acceptance criteria:

- Suggestions are tied to specific evidence.
- Suggestions avoid vague advice.
- A host can mark a suggestion as done or dismiss it.

4. As a host, I want to understand recurring review themes so that I can identify patterns that are hidden across many reviews.

Acceptance criteria:

- The app groups review feedback into themes such as cleanliness, check-in, noise, accuracy, communication, and accessibility.
- Each theme shows count, sentiment, and sample evidence.

5. As a host, I want to see accessibility completeness so that I can improve listing clarity for guests with accessibility needs.

Acceptance criteria:

- The quality report shows which accessibility details are present or missing.
- Missing fields are phrased as actionable improvements.

6. As a host, I want cached reports to load when I am offline so that I can still review my listing quality.

Acceptance criteria:

- Cached reports appear without network access.
- The UI clearly labels stale or offline data.
- Retry is available when the network returns.

7. As a host, I want quality recommendations ranked by impact so that I do not waste time on low-value changes.

Acceptance criteria:

- Recommendations are ranked using severity, frequency, recency, and confidence.
- The score impact is explained in plain language.

### Guest User Stories

1. As a guest, I want a listing trust summary so that I can quickly decide whether a stay looks reliable.

Acceptance criteria:

- The guest view shows a short trust summary.
- The summary includes at least three supporting signals.
- The summary avoids unexplained black-box scoring.

2. As a guest, I want to know if other guests have reported check-in problems so that I can avoid stressful arrivals.

Acceptance criteria:

- The guest view shows check-in reliability.
- Recent check-in issue frequency is visible.
- If there are no recent issues, the app states that clearly.

3. As a guest, I want review themes summarized so that I do not need to read every review manually.

Acceptance criteria:

- The app shows positive and negative themes.
- Themes include counts or frequency.
- Themes link back to representative review evidence.

4. As a guest, I want accessibility details surfaced clearly so that I can determine whether the listing may meet my needs.

Acceptance criteria:

- Accessibility completeness is shown separately from the overall quality score.
- Missing accessibility details are clearly identified.
- The UI does not imply verified accessibility when data is only host-provided.

5. As a guest, I want to understand what quality badges mean so that I can trust the app's recommendations.

Acceptance criteria:

- Badges have clear explanations.
- Badges are based on visible signals.
- Badge labels do not rely on color alone.

6. As a guest, I want warnings about recent quality declines so that I can avoid listings that have changed recently.

Acceptance criteria:

- The guest view shows recent negative trend signals.
- The UI distinguishes historical issues from recent issues.

## 8. Functional Requirements

### Host Dashboard

- Display listing selector.
- Display overall quality score.
- Display quality trend over recent periods.
- Display a primary insight that summarizes the most important current quality issue or opportunity.
- Display one highest-priority risk and one primary recommended action on the first screen.
- Display additional risk signals, positive signals, review themes, and score breakdowns in secondary sections.
- Display AI Quality Coach recommendations.
- Allow dismissing or completing recommendations.
- Persist dismissed and completed recommendation state.
- Avoid presenting all available metrics with equal visual weight.

### Guest Trust View

- Display listing title, host reputation, and trust summary.
- Display quality badges with explanations.
- Display check-in reliability.
- Display review themes.
- Display accessibility completeness.
- Display recent quality trend.
- Display claim type for trust badges and accessibility details when relevant: verified, host-provided, guest-reported, or inferred.
- Keep the first screen focused on the trust summary, check-in reliability, accessibility completeness, and one strongest positive or caution signal.

### Quality Report Detail

- Display score breakdown by category.
- Display evidence for each score.
- Display confidence level and data completeness for the overall report and each category.
- Display risk signals and positive signals.
- Load detail data through GraphQL.
- Fall back to cached data when offline.

### Quality Scoring

- Calculate score from weighted signals.
- Return category scores and overall score.
- Return explanation strings for the UI.
- Return confidence level and data completeness metadata.
- Prioritize recommendations by severity, frequency, recency, and expected impact.

Suggested MVP score weights:

- Cleanliness: 20 percent
- Check-in reliability: 20 percent
- Accuracy: 15 percent
- Communication: 15 percent
- Cancellation reliability: 10 percent
- Safety signals: 10 percent
- Accessibility completeness: 10 percent

These weights are heuristic MVP weights chosen for explainability. They must not be presented as statistically validated production weights. A production version would calibrate weights against historical outcomes such as guest-reported issue rates, refunds, support contacts, review declines, cancellations, and post-stay surveys.

### Networking

- Use async/await.
- Support request cancellation.
- Decode typed response models.
- Surface network, decoding, server, and empty-state errors.
- Include retry support.

### Persistence

- Cache quality reports in SwiftData.
- Cache listing summaries in SwiftData.
- Save dismissed and completed recommendations in SwiftData.
- Store simple user preferences in UserDefaults.
- Track cache timestamps.

### Accessibility

- Support Dynamic Type.
- Provide VoiceOver descriptions for numerical scores.
- Provide non-color status indicators.
- Use accessible labels for quality badges and charts.
- Maintain readable contrast.
- Label accessibility completeness as information completeness, not verified accessibility compliance unless verified evidence exists.

## 9. Success Metrics

These metrics should be presented as product success metrics, with portfolio demo proxies where real marketplace data is not available.

### Host Success Metrics

- 15 percent reduction in guest-reported check-in issues for listings that complete the recommended check-in intervention.
- 10 percent reduction in cleanliness-related negative review themes after hosts complete cleanliness recommendations.
- 20 percent increase in completed listing-quality improvements per active host.
- 25 percent reduction in unresolved high-severity quality signals after 30 days.
- 80 percent of host recommendations include clear evidence and an actionable next step.

Portfolio proxy:

- Seeded demo data shows quality score improvement after marking recommended interventions complete.
- Unit tests verify that high-frequency, recent, severe signals are prioritized above lower-impact signals.

### Guest Success Metrics

- 10 percent reduction in guest-reported listing accuracy issues after guests view trust summaries before booking.
- 15 percent reduction in guest-reported check-in issues for bookings where check-in reliability warnings were shown.
- 20 percent increase in guest confidence score in a usability test after viewing quality explanations.
- 90 percent of quality badges can be explained by visible supporting signals.

Portfolio proxy:

- Guest screen displays explanations for all trust badges.
- User testing script asks three users to identify the main risk and strongest positive signal for a listing in under 30 seconds.

### Engineering Success Metrics

- 80 percent or higher unit test coverage for the scoring engine.
- API client tests cover success, server error, decoding error, timeout, and empty data.
- Cached quality report renders offline.
- Dynamic Type and VoiceOver pass manual QA for core screens.
- App cold-start to cached dashboard render under 1 second on a modern simulator.
- Recommendation generation tests verify that no AI Quality Coach suggestion appears without evidence signals.
- Scoring tests cover sparse data behavior and confidence/data completeness output.

## 10. Out of Scope

The following are intentionally excluded from the MVP to keep the project focused and fast to complete.

- Real Airbnb integration.
- Real booking, payments, calendar availability, or messaging.
- Real enforcement actions such as suspending listings or restricting hosts.
- Real identity verification or fraud detection.
- Production ML training pipelines.
- Full review moderation.
- Multi-language localization.
- Push notifications.
- Real-time data streaming.
- Admin dashboards.
- Full GraphQL migration.
- Android or web clients.
- iPad-specific layouts.
- Complex authentication.
- Map search.
- Photo upload and image quality analysis.
- Legal policy engine.

## 11. Prioritization

### P0

- SwiftUI MVVM app shell.
- Host dashboard.
- Guest trust view.
- Quality report detail.
- REST-shaped mock API backed by bundled JSON fixtures.
- One GraphQL listing quality query.
- Quality scoring engine.
- SwiftData cache.
- Basic accessibility.
- Unit tests for scoring.

### P1

- AI Quality Coach recommendation cards.
- Offline stale-data indicators.
- Dismiss or complete recommendation state.
- Review theme summaries.
- API client error tests.
- Architecture and product docs.

### P2

- Simple trend charts.
- Usability test script.
- Optional real LLM integration.
- More advanced GraphQL schema.
- UI polish animations.
- Contributor guide and first-good-issue docs.

## 12. Risks and Mitigations

Risk: The project becomes too broad.

Mitigation: Do not build booking, messaging, maps, auth, or real enforcement. Keep the product focused on quality reputation insights.

Risk: AI feature appears hand-wavy.

Mitigation: Every recommendation must cite specific evidence signals. The AI layer should be an adapter that can be deterministic in MVP and swapped for a real LLM later.

Risk: GraphQL adds too much complexity.

Mitigation: Use GraphQL for one detail query only. Keep REST as the primary app API.

Risk: SwiftData limits older iOS support.

Mitigation: Target iOS 17 for the portfolio project. If older support becomes necessary, replace SwiftData repositories with Core Data behind the same repository protocol.

Risk: Quality scoring appears arbitrary.

Mitigation: Document weights as heuristic MVP weights, include confidence and data completeness metadata, test sparse-data behavior, and make category-level score explanations visible in the UI.

Risk: The app feels too dense for hosts or guests to scan quickly.

Mitigation: Use progressive disclosure. First screens should emphasize the primary insight, top action or caution, and the most important supporting signals. Detailed metrics, review themes, and full score breakdowns should live in secondary sections.

Risk: AI recommendations or quality badges imply unsupported claims or biased conclusions.

Mitigation: Keep the MVP recommendation layer deterministic and evidence-grounded. Require every recommendation and badge to include visible evidence and claim type. Avoid protected-class proxies, sensitive demographic inference, and absolute labels such as "safe," "unsafe," "bad host," or "fully accessible."

Risk: The project spends too much time on backend infrastructure.

Mitigation: Use bundled JSON fixtures and an injected mock API layer for the MVP. Keep the API client and repository boundaries realistic so the app still demonstrates production-style networking patterns.

## 13. Privacy, Fairness, and Safety Considerations

- Do not expose private guest details in quality reports.
- Aggregate review and issue signals where possible.
- Distinguish verified issues from inferred trends.
- Avoid implying accessibility claims are verified unless the data supports that.
- Explain quality badges and scores in plain language.
- Ground every recommendation and badge in visible evidence.
- Separate verified facts, host-provided information, guest-reported patterns, and inferred summaries.
- Avoid labels such as "safe," "unsafe," "bad host," "fully accessible," or other wording that implies unsupported certainty.
- Treat accessibility completeness as information completeness unless there is verified accessibility evidence.
- Avoid protected-class proxies and sensitive demographic inference.
- Avoid making punitive enforcement decisions in the MVP.
- Document how false positives could affect hosts and how appeals or review workflows would matter in a production system.

## 14. Leadership and Mentorship Signal

The project should include a leadership signal even though the app itself does not need a leadership feature.

This should be represented through project artifacts:

- README with clear setup and demo instructions.
- Architecture overview written for a new teammate.
- API spec and review notes that show implementation planning and cross-functional judgment.
- Short reflection connecting the project to prior SWE team lead experience in the college CS club.

If time allows after the core app is implemented, add a CONTRIBUTING guide, "first good issues" section, and short technical decision records explaining MVVM, SwiftData, GraphQL scope, and AI recommendation design.

This makes the leadership experience concrete without forcing an artificial social feature into the app.

## 15. Demo Narrative

The portfolio demo should tell this story:

1. A host opens the dashboard and sees that their listing quality score declined.
2. The top risk signal is recent check-in friction.
3. The AI Quality Coach recommends adding photo-based arrival instructions and clearer lockbox details.
4. The host marks the intervention complete.
5. The quality score projection improves.
6. A guest opens the same listing and sees a clear trust summary, check-in reliability, accessibility completeness, and review themes.
7. The guest can inspect why badges were awarded and what risks remain.

This story directly demonstrates quality signals, proactive intervention, reputation, guest protection, host improvement, explainability, and customer-facing product polish.

## 16. Resolved MVP Decisions

- Public project name: ListingLens.
- Data source: bundled JSON fixtures with an injected mock API layer.
- UI framework state management: iOS 17 Observation.
- MVP form factor: iPhone-only.
- AI layer: deterministic AI Quality Coach recommendations for MVP; real LLM integration remains out of scope unless added after the job application version is complete.

Rationale:

- These choices reduce setup and deployment overhead.
- The project still shows high-quality engineering through typed data boundaries, async flows, SwiftData caching, tests, accessibility, and clear documentation.
- The MVP stays focused on the Airbnb Quality Reputation story instead of expanding into backend, iPad, or LLM infrastructure work.

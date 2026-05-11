# ListingLens Review Notes

Status: Draft  
Related docs:

- [listinglens-prd.md](./listinglens-prd.md)
- [listinglens-architecture.md](./listinglens-architecture.md)

## Purpose

These notes capture hypothetical cross-functional feedback on ListingLens and the product/technical responses I would make as the engineer owning the MVP. The goal is to show how the project handles disagreement, ambiguity, and tradeoffs instead of treating the first PRD draft as final.

## Review Summary

| Reviewer | Concern | Response Direction |
| --- | --- | --- |
| Lead Designer | The host dashboard and guest trust view may be too dense. | Reduce first-screen complexity, progressive disclosure, clearer hierarchy, and separate host actioning from investigation. |
| Data Scientist | The scoring weights look arbitrary and may create misleading quality scores. | Treat weights as an MVP baseline, add calibration docs/tests, expose category-level explanations, and avoid claiming production validity. |
| Legal Counsel | AI recommendations and trust badges could encode bias or imply unsupported claims. | Keep AI deterministic and evidence-grounded, avoid protected-class proxies, add disclaimers, and distinguish verified facts from inferred patterns. |

## 1. Lead Designer Feedback: Data Density

### Critique

The dashboard is trying to do too much at once: overall score, trend, top positive signals, top risk signals, recommendation cards, review themes, accessibility completeness, and offline status. This may read like an internal operations tool instead of a customer-facing product. Hosts need to know what to do next, and guests need a fast trust read. The app risks burying the answer under too many metrics.

### Response

I agree with the core concern. The PRD correctly identifies the signals that matter, but the UI should not expose all of them with equal weight. The product goal is not to prove how much data we have; it is to help hosts take the next best action and help guests understand trust quickly.

For the MVP, I would keep the underlying data model and scoring system intact but change the presentation hierarchy:

- Host first screen: overall quality score, trend, one highest-priority risk, and one primary recommended action.
- Host secondary sections: additional risk signals, positive signals, review themes, and score breakdown.
- Guest first screen: trust summary, check-in reliability, accessibility completeness, and one strongest positive or caution signal.
- Guest secondary sections: badge explanations, review themes, host reputation, and recent trend details.

This keeps the system technically rich while making the interface easier to scan. The architecture already supports this because ViewModels can fetch full `QualityReport` objects while Views choose which fields to reveal first.

### Tradeoff

Reducing first-screen density means some portfolio signals are less visible in the initial screenshot. I think that is acceptable. A better portfolio project should show product judgment, not just feature volume. The detailed screens, README, and architecture document can demonstrate the full technical scope without forcing every signal into the first viewport.

### Follow-Up Changes

- Add a "primary insight" field to the host dashboard ViewModel, derived from the top recommendation and top risk signal.
- Treat charts and full score breakdowns as drill-down content, not first-screen content.
- Add empty and low-data states so sparse listings do not show fake precision.
- Use visual hierarchy rules: one primary metric, one primary action, then supporting context.

## 2. Data Scientist Feedback: Scoring Weights

### Critique

The proposed score weights are plausible but arbitrary. Cleanliness and check-in are each 20 percent, accessibility is 10 percent, safety is 10 percent, and so on. Without historical outcome data, these weights could misrepresent actual guest harm or create false confidence. A single quality score may also hide uncertainty and data sparsity.

### Response

I agree that the current weights should not be presented as statistically validated. In this portfolio MVP, the scoring engine is meant to demonstrate systems thinking, deterministic logic, and explainability. It is not a trained marketplace ranking model.

I would handle this in four ways:

1. Label the score as a demo quality score, not a production trust score.
2. Show category-level contributions so users can see what drove the result.
3. Include confidence and data sufficiency metadata alongside the score.
4. Write unit tests that verify consistency and prioritization behavior rather than pretending the weights are empirically optimal.

The production version would calibrate weights against historical outcomes such as check-in issue reports, refund/contact rates, review declines, cancellations, repeat booking behavior, and post-stay quality surveys. It would also require offline evaluation before any user-facing launch.

### Tradeoff

A deterministic weighted score is faster to build and easier to explain in interviews than a learned model. The downside is that it can look oversimplified. The mitigation is transparency: expose inputs, weights, and confidence instead of presenting the score as an opaque truth.

### Follow-Up Changes

- Add `confidenceLevel` to `QualityReport`.
- Add `dataCompleteness` or `evidenceCount` to each category score.
- Document that MVP weights are heuristic and selected for explainability.
- Add tests for sparse data behavior, such as listings with few reviews or no recent signals.
- Add a future technical decision record describing how weights would be validated with real outcome data.

### Example Product Copy Adjustment

Instead of:

> Quality Score: 84

Use:

> Quality Score: 84, high confidence, based on recent reviews, check-in reports, and host reliability signals.

For sparse data:

> Limited quality history. Showing available signals without a full confidence rating.

## 3. Legal Counsel Feedback: AI Bias and Unsupported Claims

### Critique

AI-generated recommendations and guest-facing trust badges could introduce bias, especially if review text reflects subjective or discriminatory guest behavior. The app may also imply that accessibility information, safety status, or host reliability has been verified when it is only inferred from incomplete data. If the system produces recommendations or warnings, hosts may be unfairly penalized by low-quality or biased inputs.

### Response

This is the highest-risk critique because it affects user trust and fairness. For the MVP, the AI Quality Coach should remain deterministic and evidence-grounded. It should summarize visible signals rather than generate unsupported claims. The system should not make enforcement decisions, suppress listings, rank marketplace supply, or label hosts as unsafe.

I would make three product boundaries explicit:

- AI recommendations are coaching suggestions for hosts, not punitive actions.
- Guest trust badges are explainable summaries of available signals, not guarantees.
- Accessibility completeness means information completeness, not verified accessibility compliance.

The app should also avoid using protected-class proxies or sensitive demographic inference. Review themes should focus on stay-quality categories from the PRD: cleanliness, check-in, accuracy, communication, safety reports, cancellation reliability, and accessibility detail completeness.

### Tradeoff

Stronger warnings may help guests avoid bad stays, but overly confident warnings can harm hosts and create legal risk. The MVP should favor careful wording, evidence links, and uncertainty over aggressive risk labels. This may make the product feel less decisive, but it is more responsible and closer to how a real trust product should behave.

### Follow-Up Changes

- Add an `evidence` section to every recommendation and badge.
- Add a `claimType` field: `verified`, `hostProvided`, `guestReported`, or `inferred`.
- Avoid labels like "safe", "unsafe", "bad host", or "fully accessible".
- Use labels like "recent check-in concerns reported" or "accessibility details incomplete."
- Add a fairness review checklist to the README before public release.
- Add tests that prevent recommendations from being generated without evidence signals.

### Example Legal-Safe Copy

Avoid:

> This listing is accessible.

Use:

> Accessibility details are 80 percent complete based on host-provided information.

Avoid:

> This host is unreliable.

Use:

> Recent guest reports mention delayed responses and check-in friction.

Avoid:

> AI detected a risky stay.

Use:

> Suggested host action based on recent check-in and review signals.

## Resulting Product Adjustments

The review does not require changing the core MVP architecture. It does require tightening the presentation, metadata, and language around quality insights.

Accepted changes:

- Keep MVVM, SwiftData, REST, GraphQL detail query, and deterministic recommendation adapter.
- Add confidence and data completeness metadata to quality reports.
- Use progressive disclosure to reduce first-screen data density.
- Ground every recommendation and badge in visible evidence.
- Separate verified facts, host-provided information, guest-reported patterns, and inferred summaries.
- Make score weights transparent and documented as heuristic MVP weights.

Deferred changes:

- No production ML calibration in the MVP.
- No real enforcement workflows.
- No marketplace ranking or listing suppression.
- No legal policy engine.

## Interview Talking Points

- I treated design feedback as a signal to improve prioritization, not as a request to remove technical depth.
- I treated data science feedback as a validity concern and responded with confidence metadata, calibration plans, and transparent scoring.
- I treated legal feedback as a product boundary issue: the MVP can coach and explain, but it should not overclaim, enforce, or hide uncertainty.
- The main technical decision was to keep the domain model rich while making the UI progressively disclose complexity.
- The main product decision was to make the system explainable even when that means the product sounds less absolute.

# ListingLens API Specification

Status: Draft for bundled JSON/mock API implementation  
Related docs:

- [PRD](./listinglens-prd.md)
- [Architecture](./listinglens-architecture.md)

## 1. Purpose

ListingLens uses a mock REST API pattern backed by bundled JSON fixtures. This spec defines the REST-shaped contract that should guide:

- Bundled fixture files in the iOS app.
- Swift DTOs and decoding tests.
- Repository behavior for stale-while-refresh quality reports.
- Error-state fixtures for offline, not-found, malformed, and scoring-failure flows.

The mock API should feel like a real service boundary even though no backend is shipped for the MVP. The Swift layer should call typed clients and repositories, not read fixture files directly from Views or ViewModels.

## 2. API Conventions

Base path: `/v1`

Recommended fixture folder:

```text
ListingLens/Resources/MockAPI/
  listings.index.json
  listings.stay_1001.quality_report.json
  graphql.listing_quality_details.stay_1001.json
  hosts.host_501.reputation.json
  quality.signals.create.success.json
  recommendations.interventions.suggest.success.json
  recommendations.interventions.dismiss.success.json
  errors.listing_not_found.json
  errors.scoring_engine_failure.json
```

### Common Types

| Field | Type | Notes |
| --- | --- | --- |
| `id` | `String` | Stable fixture ID. Use readable IDs such as `stay_1001`, `host_501`, `sig_checkin_001`. |
| `score` | `Int` | 0-100 unless otherwise noted. |
| `weight` | `Double` | 0.0-1.0. Category weights should sum to 1.0. |
| `confidenceLevel` | `String` | `high`, `medium`, `low`, or `insufficientData`. |
| `claimType` | `String` | `verified`, `hostProvided`, `guestReported`, or `inferred`. |
| `severity` | `String` | `low`, `medium`, `high`, or `critical`. |
| `trendDirection` | `String` | `improving`, `stable`, `declining`, or `insufficientData`. |
| `recommendationStatus` | `String` | `suggested`, `dismissed`, or `completed`. |
| `createdAt`, `updatedAt`, `fetchedAt` | `String` | ISO 8601 date-time. |

### Error Envelope

All error fixtures should use one envelope so Swift error decoding is simple.

```json
{
  "error": {
    "code": "listing_not_found",
    "message": "Listing was not found.",
    "details": {
      "listingId": "stay_missing"
    },
    "requestId": "mock_req_404_listing",
    "retryable": false
  }
}
```

Common error codes:

| HTTP Status | Code | Retryable | Use |
| --- | --- | --- | --- |
| `404` | `listing_not_found` | `false` | Requested listing fixture does not exist. |
| `404` | `host_not_found` | `false` | Requested host fixture does not exist. |
| `500` | `scoring_engine_failure` | `true` | Quality scoring fixture simulates service failure. |
| `500` | `recommendation_engine_failure` | `true` | AI Quality Coach fixture simulates recommendation failure. |
| `422` | `invalid_signal_payload` | `false` | Posted signal payload is missing required fields. |

### GraphQL-Shaped Fixture Contract

The MVP includes one GraphQL-shaped query to demonstrate GraphQL modeling without adding a real GraphQL backend. The fixture transport should route this query by operation name and variables, then decode the response through a typed `GraphQLClient`.

Operation name: `ListingQualityDetails`

Variables:

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `listingId` | `ID` | Yes | Listing ID, such as `stay_1001`. |

Query:

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
        confidenceLevel
        dataCompleteness
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

Recommended fixture name: `graphql.listing_quality_details.stay_1001.json`

Success response shape:

```json
{
  "data": {
    "listing": {
      "id": "stay_1001",
      "title": "Bright Mission Studio Near Transit",
      "qualityReport": {
        "overallScore": 84,
        "confidenceLevel": "high",
        "dataCompleteness": 0.92,
        "scoreBreakdown": [
          {
            "category": "checkInReliability",
            "score": 68,
            "weight": 0.2,
            "weightedContribution": 13.6,
            "confidenceLevel": "high",
            "dataCompleteness": 0.9,
            "explanation": "Four recent reviews mention difficulty finding the lockbox or entrance after dark."
          }
        ],
        "riskSignals": [
          {
            "id": "sig_checkin_001",
            "category": "checkInReliability",
            "severity": "high",
            "claimType": "guestReported",
            "title": "Guests report lockbox confusion",
            "explanation": "Four check-in complaints in the last 30 days mention the lockbox location."
          }
        ],
        "positiveSignals": [
          {
            "id": "sig_clean_001",
            "category": "cleanliness",
            "claimType": "guestReported",
            "title": "Cleanliness is consistently praised",
            "explanation": "Nine recent reviews mention spotless surfaces, clean linens, or a clean bathroom."
          }
        ]
      }
    }
  }
}
```

GraphQL errors should use the standard GraphQL `errors` array while preserving the same code names used by REST fixtures.

```json
{
  "data": {
    "listing": null
  },
  "errors": [
    {
      "message": "No listing fixture exists for id stay_missing.",
      "extensions": {
        "code": "listing_not_found",
        "retryable": false,
        "requestId": "mock_gql_404_listing_quality"
      }
    }
  ]
}
```

## 3. Endpoint: List Listings

### Method & Path

`GET /v1/listings`

### Description

Returns listing summaries for the discovery view, host listing selector, and guest trust entry point. This endpoint supports fast first-screen rendering and should avoid deep report data. The app may cache this response in SwiftData as `CachedListing` rows.

### Query Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `persona` | `String` | No | `host` or `guest`. Allows fixture filtering for demo flows. |
| `location` | `String` | No | Case-insensitive city or neighborhood filter. |
| `includeSavedState` | `Bool` | No | If `true`, includes whether the listing is saved locally in the mock payload. |
| `limit` | `Int` | No | Maximum number of listings. Default fixture can ignore this but Swift client should encode it. |

### Request Body

None.

### Success Response: 200 OK

```json
{
  "data": [
    {
      "id": "stay_1001",
      "title": "Bright Mission Studio Near Transit",
      "locationSummary": "Mission District, San Francisco",
      "thumbnailURL": "mock://images/stay_1001_hero",
      "host": {
        "id": "host_501",
        "displayName": "Maya",
        "isSuperhostLike": true,
        "responseTimeMinutes": 42
      },
      "summary": {
        "overallScore": 84,
        "confidenceLevel": "high",
        "dataCompleteness": 0.92,
        "trendDirection": "declining",
        "primaryInsight": {
          "title": "Check-in friction is increasing",
          "description": "Recent reviews mention difficulty finding the lockbox and entrance after dark.",
          "severity": "high",
          "claimType": "guestReported"
        }
      },
      "badges": [
        {
          "id": "badge_reliable_host",
          "label": "Reliable host",
          "explanation": "Host response time and cancellation history are stronger than the fixture baseline.",
          "claimType": "inferred"
        },
        {
          "id": "badge_accessibility_details",
          "label": "Accessibility details available",
          "explanation": "Host has provided step-free access, elevator, and doorway detail fields.",
          "claimType": "hostProvided"
        }
      ],
      "accessibilitySummary": {
        "completenessScore": 80,
        "claimType": "hostProvided",
        "stepFreeAccess": true,
        "elevator": true,
        "wideDoorways": false
      },
      "updatedAt": "2026-05-10T18:25:00Z"
    },
    {
      "id": "stay_1002",
      "title": "Quiet Garden Room by Lake Union",
      "locationSummary": "Eastlake, Seattle",
      "thumbnailURL": "mock://images/stay_1002_hero",
      "host": {
        "id": "host_502",
        "displayName": "Jon",
        "isSuperhostLike": false,
        "responseTimeMinutes": 118
      },
      "summary": {
        "overallScore": 76,
        "confidenceLevel": "medium",
        "dataCompleteness": 0.74,
        "trendDirection": "stable",
        "primaryInsight": {
          "title": "Accuracy details need review",
          "description": "Several reviews mention that street noise is higher than expected.",
          "severity": "medium",
          "claimType": "guestReported"
        }
      },
      "badges": [
        {
          "id": "badge_clean_reviews",
          "label": "Consistent cleanliness",
          "explanation": "Cleanliness mentions are positive across recent review themes.",
          "claimType": "guestReported"
        }
      ],
      "accessibilitySummary": {
        "completenessScore": 45,
        "claimType": "hostProvided",
        "stepFreeAccess": false,
        "elevator": false,
        "wideDoorways": null
      },
      "updatedAt": "2026-05-09T21:10:00Z"
    }
  ],
  "meta": {
    "count": 2,
    "fetchedAt": "2026-05-10T19:00:00Z",
    "fixtureName": "listings.index.json"
  }
}
```

### Error States

#### 500 Scoring Engine Failure

Used to test discovery fallback when summary scores cannot be computed.

```json
{
  "error": {
    "code": "scoring_engine_failure",
    "message": "Listing summaries could not be scored.",
    "details": {
      "failedStage": "listing_summary_rollup"
    },
    "requestId": "mock_req_500_listings",
    "retryable": true
  }
}
```

## 4. Endpoint: Listing Quality Report

### Method & Path

`GET /v1/listings/{id}/quality-report`

### Description

Returns the deep-dive quality intelligence for a single listing. This is the primary stale-while-refresh endpoint. The app should render the cached version immediately from SwiftData, then refresh this endpoint through the fixture transport to update score, evidence, recommendation, and freshness metadata.

This endpoint supports:

- Host dashboard score and primary insight.
- Guest trust summary and quality badges.
- Quality Report Detail screen.
- AI Quality Coach evidence and intervention ranking.
- Offline support and stale-data banners.

### Path Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `id` | `String` | Yes | Listing ID, such as `stay_1001`. |

### Query Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `includeReviews` | `Bool` | No | If `true`, includes representative review excerpts. Default `true` for fixture. |
| `includeRecommendations` | `Bool` | No | If `true`, includes AI Quality Coach recommendations. Default `true`. |
| `refreshReason` | `String` | No | `initialLoad`, `pullToRefresh`, `staleWhileRefresh`, or `retry`. |

### Request Body

None.

### Success Response: 200 OK

```json
{
  "data": {
    "listing": {
      "id": "stay_1001",
      "title": "Bright Mission Studio Near Transit",
      "locationSummary": "Mission District, San Francisco",
      "hostId": "host_501"
    },
    "qualityReport": {
      "id": "qr_stay_1001_2026_05_10",
      "listingId": "stay_1001",
      "overallScore": 84,
      "confidenceLevel": "high",
      "dataCompleteness": 0.92,
      "trend": {
        "direction": "declining",
        "delta30Days": -6,
        "summary": "Quality score declined due to recent check-in friction."
      },
      "scoreBreakdown": [
        {
          "category": "cleanliness",
          "label": "Cleanliness",
          "score": 91,
          "weight": 0.2,
          "weightedContribution": 18.2,
          "confidenceLevel": "high",
          "dataCompleteness": 0.95,
          "evidenceCount": 18,
          "explanation": "Recent reviews consistently mention clean linens and a spotless bathroom."
        },
        {
          "category": "checkInReliability",
          "label": "Check-in reliability",
          "score": 68,
          "weight": 0.2,
          "weightedContribution": 13.6,
          "confidenceLevel": "high",
          "dataCompleteness": 0.9,
          "evidenceCount": 7,
          "explanation": "Four recent reviews mention difficulty finding the lockbox or entrance after dark."
        },
        {
          "category": "accuracy",
          "label": "Accuracy",
          "score": 86,
          "weight": 0.15,
          "weightedContribution": 12.9,
          "confidenceLevel": "medium",
          "dataCompleteness": 0.78,
          "evidenceCount": 9,
          "explanation": "Most guests say the listing matches the photos, with some noise-context gaps."
        },
        {
          "category": "communication",
          "label": "Communication",
          "score": 88,
          "weight": 0.15,
          "weightedContribution": 13.2,
          "confidenceLevel": "high",
          "dataCompleteness": 0.94,
          "evidenceCount": 14,
          "explanation": "Host response time is under one hour for most guest questions."
        },
        {
          "category": "cancellationReliability",
          "label": "Cancellation reliability",
          "score": 96,
          "weight": 0.1,
          "weightedContribution": 9.6,
          "confidenceLevel": "high",
          "dataCompleteness": 1.0,
          "evidenceCount": 0,
          "explanation": "No host-initiated cancellations in the fixture history."
        },
        {
          "category": "safetySignals",
          "label": "Safety signals",
          "score": 90,
          "weight": 0.1,
          "weightedContribution": 9.0,
          "confidenceLevel": "medium",
          "dataCompleteness": 0.7,
          "evidenceCount": 1,
          "explanation": "One low-severity report was resolved; no recent critical safety reports."
        },
        {
          "category": "accessibilityCompleteness",
          "label": "Accessibility completeness",
          "score": 80,
          "weight": 0.1,
          "weightedContribution": 8.0,
          "confidenceLevel": "medium",
          "dataCompleteness": 0.8,
          "evidenceCount": 6,
          "explanation": "Host provided most accessibility detail fields, but doorway width is missing."
        }
      ],
      "primaryInsight": {
        "title": "Improve check-in clarity",
        "description": "Check-in reliability is the lowest weighted category and is driving the recent decline.",
        "severity": "high",
        "claimType": "inferred",
        "evidenceSignalIds": ["sig_checkin_001", "theme_checkin_lockbox"]
      },
      "riskSignals": [
        {
          "id": "sig_checkin_001",
          "category": "checkInReliability",
          "severity": "high",
          "claimType": "guestReported",
          "title": "Guests report lockbox confusion",
          "explanation": "Four check-in complaints in the last 30 days mention the lockbox location.",
          "frequency": 4,
          "firstSeenAt": "2026-04-14T12:00:00Z",
          "lastSeenAt": "2026-05-08T20:41:00Z",
          "source": "reviewThemes"
        },
        {
          "id": "sig_accuracy_002",
          "category": "accuracy",
          "severity": "medium",
          "claimType": "guestReported",
          "title": "Street noise context is incomplete",
          "explanation": "Two recent reviews mention street noise after 10 PM.",
          "frequency": 2,
          "firstSeenAt": "2026-04-20T09:00:00Z",
          "lastSeenAt": "2026-05-02T16:15:00Z",
          "source": "reviewThemes"
        }
      ],
      "positiveSignals": [
        {
          "id": "sig_clean_001",
          "category": "cleanliness",
          "severity": "low",
          "claimType": "guestReported",
          "title": "Cleanliness is consistently praised",
          "explanation": "Nine recent reviews mention spotless surfaces, clean linens, or a clean bathroom.",
          "frequency": 9,
          "source": "reviewThemes"
        },
        {
          "id": "sig_host_001",
          "category": "communication",
          "severity": "low",
          "claimType": "verified",
          "title": "Fast host response time",
          "explanation": "Median response time is 42 minutes across recent guest messages.",
          "frequency": 12,
          "source": "hostMetrics"
        }
      ],
      "aiSignals": {
        "summary": "Guests are happy with cleanliness and communication, but recent check-in comments suggest preventable arrival friction.",
        "claimType": "inferred",
        "generatedBy": "deterministicQualityCoach",
        "themes": [
          {
            "id": "theme_checkin_lockbox",
            "label": "Lockbox hard to find",
            "category": "checkInReliability",
            "sentiment": "negative",
            "mentions": 4,
            "representativeEvidence": [
              {
                "reviewId": "rev_9001",
                "excerpt": "The room was great, but I walked past the lockbox twice in the dark.",
                "createdAt": "2026-05-08T20:41:00Z"
              },
              {
                "reviewId": "rev_8994",
                "excerpt": "Clearer arrival photos would have helped a lot.",
                "createdAt": "2026-04-28T18:20:00Z"
              }
            ]
          },
          {
            "id": "theme_cleanliness_positive",
            "label": "Clean and well stocked",
            "category": "cleanliness",
            "sentiment": "positive",
            "mentions": 9,
            "representativeEvidence": [
              {
                "reviewId": "rev_8998",
                "excerpt": "The studio was spotless and had everything I needed.",
                "createdAt": "2026-05-03T17:30:00Z"
              }
            ]
          }
        ]
      },
      "accessibility": {
        "claimType": "hostProvided",
        "completenessScore": 80,
        "lastUpdatedAt": "2026-04-25T10:00:00Z",
        "disclaimer": "Accessibility details are host-provided information completeness, not verified accessibility compliance.",
        "features": {
          "stepFreeAccess": {
            "available": true,
            "claimType": "hostProvided",
            "details": "Step-free path from sidewalk to building entrance."
          },
          "elevator": {
            "available": true,
            "claimType": "hostProvided",
            "details": "Elevator available from lobby to unit floor."
          },
          "wideDoorways": {
            "available": false,
            "claimType": "hostProvided",
            "details": "Doorway width not confirmed."
          },
          "accessibleParking": {
            "available": false,
            "claimType": "hostProvided",
            "details": "No dedicated accessible parking listed."
          },
          "stepFreeShower": {
            "available": true,
            "claimType": "hostProvided",
            "details": "Shower entry is listed as step-free."
          },
          "captionsOnMedia": {
            "available": true,
            "claimType": "verified",
            "details": "Listing video captions are present in fixture metadata."
          },
          "serviceAnimalPolicyClarity": {
            "available": true,
            "claimType": "hostProvided",
            "details": "Listing rules include service-animal policy guidance."
          }
        },
        "missingFields": [
          "wideDoorwayMeasurements",
          "bathroomGrabBarDetails"
        ]
      },
      "recommendations": [
        {
          "id": "rec_checkin_photos_001",
          "listingId": "stay_1001",
          "title": "Add photo-based arrival instructions",
          "hostAction": "Upload three photos showing the entrance, lockbox location, and door code sequence.",
          "expectedImpact": "Reduce guest-reported check-in issues.",
          "confidenceLevel": "high",
          "claimType": "inferred",
          "status": "suggested",
          "priorityScore": 94,
          "evidenceSignalIds": ["sig_checkin_001", "theme_checkin_lockbox"],
          "createdAt": "2026-05-10T19:00:00Z"
        }
      ],
      "freshness": {
        "fetchedAt": "2026-05-10T19:00:00Z",
        "expiresAt": "2026-05-10T19:30:00Z",
        "schemaVersion": 1
      }
    }
  },
  "meta": {
    "fixtureName": "listings.stay_1001.quality_report.json",
    "requestId": "mock_req_quality_stay_1001",
    "generatedAt": "2026-05-10T19:00:00Z"
  }
}
```

### Error States

#### 404 Listing Not Found

```json
{
  "error": {
    "code": "listing_not_found",
    "message": "No listing fixture exists for id stay_missing.",
    "details": {
      "listingId": "stay_missing",
      "fixtureLookup": "listings.stay_missing.quality_report.json"
    },
    "requestId": "mock_req_404_quality_report",
    "retryable": false
  }
}
```

#### 500 Scoring Engine Failure

```json
{
  "error": {
    "code": "scoring_engine_failure",
    "message": "The mock scoring engine failed while building the quality report.",
    "details": {
      "listingId": "stay_1001",
      "failedStage": "weighted_score_breakdown",
      "fallbackBehavior": "show_cached_report_if_available"
    },
    "requestId": "mock_req_500_quality_report",
    "retryable": true
  }
}
```

## 5. Endpoint: Host Reputation

### Method & Path

`GET /v1/hosts/{id}/reputation`

### Description

Returns host-level reliability and reputation metrics. This supports host dashboard context, guest trust summaries, and listing-level quality explanations. Host metrics should not make unsupported personal judgments; they should summarize observable reliability signals such as response time, cancellation behavior, and recurring review themes.

### Path Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `id` | `String` | Yes | Host ID, such as `host_501`. |

### Query Parameters

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `includeHistory` | `Bool` | No | If `true`, includes monthly history. Default `true` for fixture. |
| `windowDays` | `Int` | No | Analysis window. Default `90`. |

### Request Body

None.

### Success Response: 200 OK

```json
{
  "data": {
    "host": {
      "id": "host_501",
      "displayName": "Maya",
      "joinedAt": "2021-08-14T00:00:00Z",
      "activeListingIds": ["stay_1001", "stay_1010"]
    },
    "reputation": {
      "overallScore": 89,
      "confidenceLevel": "high",
      "dataCompleteness": 0.91,
      "claimType": "inferred",
      "summary": "Strong response and cancellation history, with recent check-in clarity issues isolated to one listing.",
      "metrics": {
        "medianResponseTimeMinutes": 42,
        "responseRate": 0.98,
        "hostInitiatedCancellationRate": 0.0,
        "resolvedIssueRate": 0.86,
        "averageRating": 4.84,
        "reviewCount": 126
      },
      "history": [
        {
          "period": "2026-03",
          "overallScore": 91,
          "guestReportedIssueCount": 2,
          "hostInitiatedCancellations": 0
        },
        {
          "period": "2026-04",
          "overallScore": 88,
          "guestReportedIssueCount": 5,
          "hostInitiatedCancellations": 0
        },
        {
          "period": "2026-05",
          "overallScore": 89,
          "guestReportedIssueCount": 3,
          "hostInitiatedCancellations": 0
        }
      ],
      "positiveSignals": [
        {
          "id": "host_sig_response_001",
          "category": "communication",
          "title": "Fast median response time",
          "explanation": "Median response time is 42 minutes over the last 90 days.",
          "claimType": "verified"
        }
      ],
      "riskSignals": [
        {
          "id": "host_sig_checkin_001",
          "category": "checkInReliability",
          "title": "Check-in issues concentrated on one listing",
          "explanation": "Recent check-in reports are tied to stay_1001 rather than all host listings.",
          "severity": "medium",
          "claimType": "guestReported"
        }
      ]
    }
  },
  "meta": {
    "fixtureName": "hosts.host_501.reputation.json",
    "fetchedAt": "2026-05-10T19:00:00Z"
  }
}
```

### Error States

#### 404 Host Not Found

```json
{
  "error": {
    "code": "host_not_found",
    "message": "No host fixture exists for id host_missing.",
    "details": {
      "hostId": "host_missing"
    },
    "requestId": "mock_req_404_host",
    "retryable": false
  }
}
```

#### 500 Scoring Engine Failure

```json
{
  "error": {
    "code": "scoring_engine_failure",
    "message": "The mock scoring engine failed while building host reputation.",
    "details": {
      "hostId": "host_501",
      "failedStage": "host_reputation_rollup"
    },
    "requestId": "mock_req_500_host",
    "retryable": true
  }
}
```

## 6. Endpoint: Create Quality Signal

### Method & Path

`POST /v1/quality/signals`

### Description

Creates a new quality signal, such as a reported check-in issue, cleanliness concern, accessibility detail update, or safety-related report. In the MVP, this endpoint is mocked and should return a deterministic success fixture. The app can use it to demonstrate request-body encoding, optimistic local state, validation errors, and quality report refresh after a new signal is submitted.

This endpoint does not perform enforcement. It only records an input signal that can later influence quality scoring and recommendations.

### Query Parameters

None.

### Request Body

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `listingId` | `String` | Yes | Listing receiving the signal. |
| `hostId` | `String` | No | Host ID if known. |
| `category` | `String` | Yes | `cleanliness`, `checkInReliability`, `accuracy`, `communication`, `cancellationReliability`, `safetySignals`, or `accessibilityCompleteness`. |
| `source` | `String` | Yes | `guestReport`, `hostUpdate`, `reviewTheme`, `supportCase`, or `systemGenerated`. |
| `severity` | `String` | Yes | `low`, `medium`, `high`, or `critical`. |
| `claimType` | `String` | Yes | Usually `guestReported`, `hostProvided`, or `verified`. |
| `title` | `String` | Yes | Short signal title. |
| `description` | `String` | Yes | Human-readable explanation. |
| `occurredAt` | `String` | Yes | ISO 8601 timestamp. |
| `evidence` | `Array<Object>` | No | Supporting review, report, or host-update evidence. |

Example:

```json
{
  "listingId": "stay_1001",
  "hostId": "host_501",
  "category": "checkInReliability",
  "source": "guestReport",
  "severity": "high",
  "claimType": "guestReported",
  "title": "Guest could not locate lockbox",
  "description": "Guest reported that the lockbox was hard to find after sunset.",
  "occurredAt": "2026-05-10T03:20:00Z",
  "evidence": [
    {
      "type": "guestReport",
      "id": "guest_report_7001",
      "excerpt": "I arrived late and could not tell which lockbox belonged to the unit."
    }
  ]
}
```

### Success Response: 200 OK

```json
{
  "data": {
    "signal": {
      "id": "sig_checkin_010",
      "listingId": "stay_1001",
      "hostId": "host_501",
      "category": "checkInReliability",
      "source": "guestReport",
      "severity": "high",
      "claimType": "guestReported",
      "title": "Guest could not locate lockbox",
      "explanation": "Guest reported that the lockbox was hard to find after sunset.",
      "createdAt": "2026-05-10T19:05:00Z",
      "occurredAt": "2026-05-10T03:20:00Z",
      "evidence": [
        {
          "type": "guestReport",
          "id": "guest_report_7001",
          "excerpt": "I arrived late and could not tell which lockbox belonged to the unit."
        }
      ]
    },
    "qualityReportRefresh": {
      "recommended": true,
      "reason": "New high-severity check-in signal may affect score and recommendation priority.",
      "refreshEndpoint": "/v1/listings/stay_1001/quality-report"
    }
  },
  "meta": {
    "fixtureName": "quality.signals.create.success.json",
    "requestId": "mock_req_create_signal",
    "fetchedAt": "2026-05-10T19:05:00Z"
  }
}
```

### Error States

#### 404 Listing Not Found

```json
{
  "error": {
    "code": "listing_not_found",
    "message": "Cannot create a signal for unknown listing stay_missing.",
    "details": {
      "listingId": "stay_missing"
    },
    "requestId": "mock_req_404_create_signal",
    "retryable": false
  }
}
```

#### 422 Invalid Signal Payload

```json
{
  "error": {
    "code": "invalid_signal_payload",
    "message": "Signal payload is missing required fields.",
    "details": {
      "missingFields": ["category", "severity", "description"]
    },
    "requestId": "mock_req_422_create_signal",
    "retryable": false
  }
}
```

#### 500 Scoring Engine Failure

```json
{
  "error": {
    "code": "scoring_engine_failure",
    "message": "Signal was accepted, but the quality report refresh failed.",
    "details": {
      "listingId": "stay_1001",
      "signalAccepted": true,
      "failedStage": "post_signal_score_refresh"
    },
    "requestId": "mock_req_500_create_signal",
    "retryable": true
  }
}
```

## 7. Endpoint: Recommendation Interventions

### Method & Path

`POST /v1/recommendations/interventions`

### Description

Supports the AI Quality Coach interaction. The same endpoint can be used to request suggested interventions for a listing or update the local state of an existing intervention, such as dismissing or completing it.

For the MVP, the recommendation engine is deterministic and fixture-backed. Recommendations must be evidence-grounded and include `claimType`, `confidenceLevel`, and `evidenceSignalIds`.

### Query Parameters

None.

### Request Body

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `action` | `String` | Yes | `suggest`, `dismiss`, or `complete`. |
| `listingId` | `String` | Yes | Listing ID. |
| `recommendationId` | `String` | Required for `dismiss` and `complete` | Recommendation to update. |
| `reason` | `String` | No | Optional host-selected reason for dismissing. |
| `completedAt` | `String` | No | ISO 8601 timestamp for completed intervention. |
| `context` | `Object` | No | Optional report version or visible signal IDs from the current UI state. |

Suggest example:

```json
{
  "action": "suggest",
  "listingId": "stay_1001",
  "context": {
    "qualityReportId": "qr_stay_1001_2026_05_10",
    "visibleSignalIds": ["sig_checkin_001", "sig_accuracy_002"]
  }
}
```

Dismiss example:

```json
{
  "action": "dismiss",
  "listingId": "stay_1001",
  "recommendationId": "rec_checkin_photos_001",
  "reason": "Host already updated instructions outside the app"
}
```

### Success Response: 200 OK

```json
{
  "data": {
    "listingId": "stay_1001",
    "action": "suggest",
    "recommendations": [
      {
        "id": "rec_checkin_photos_001",
        "listingId": "stay_1001",
        "title": "Add photo-based arrival instructions",
        "hostAction": "Upload three photos showing the entrance, lockbox location, and door code sequence.",
        "expectedImpact": "Reduce guest-reported check-in issues.",
        "confidenceLevel": "high",
        "claimType": "inferred",
        "status": "suggested",
        "priorityScore": 94,
        "rankingFactors": {
          "severity": "high",
          "frequency": 4,
          "recencyDays": 2,
          "expectedImpact": "high"
        },
        "evidenceSignalIds": ["sig_checkin_001", "theme_checkin_lockbox"],
        "evidence": [
          {
            "id": "sig_checkin_001",
            "type": "qualitySignal",
            "summary": "Four check-in complaints in the last 30 days mention lockbox location."
          },
          {
            "id": "theme_checkin_lockbox",
            "type": "reviewTheme",
            "summary": "Guests mention difficulty finding the entrance after dark."
          }
        ],
        "createdAt": "2026-05-10T19:00:00Z",
        "updatedAt": "2026-05-10T19:00:00Z"
      },
      {
        "id": "rec_accessibility_measurements_001",
        "listingId": "stay_1001",
        "title": "Add doorway width measurements",
        "hostAction": "Measure and add bedroom, bathroom, and entry doorway widths.",
        "expectedImpact": "Improve accessibility information completeness.",
        "confidenceLevel": "medium",
        "claimType": "inferred",
        "status": "suggested",
        "priorityScore": 71,
        "rankingFactors": {
          "severity": "medium",
          "frequency": 1,
          "recencyDays": 15,
          "expectedImpact": "medium"
        },
        "evidenceSignalIds": ["access_missing_wide_doorway_measurements"],
        "evidence": [
          {
            "id": "access_missing_wide_doorway_measurements",
            "type": "accessibilityFieldGap",
            "summary": "Wide doorway measurements are missing from host-provided accessibility details."
          }
        ],
        "createdAt": "2026-05-10T19:00:00Z",
        "updatedAt": "2026-05-10T19:00:00Z"
      }
    ]
  },
  "meta": {
    "fixtureName": "recommendations.interventions.suggest.success.json",
    "requestId": "mock_req_recommend_suggest",
    "fetchedAt": "2026-05-10T19:00:00Z"
  }
}
```

Dismiss success example:

```json
{
  "data": {
    "listingId": "stay_1001",
    "action": "dismiss",
    "recommendation": {
      "id": "rec_checkin_photos_001",
      "status": "dismissed",
      "dismissedAt": "2026-05-10T19:15:00Z",
      "dismissReason": "Host already updated instructions outside the app"
    }
  },
  "meta": {
    "fixtureName": "recommendations.interventions.dismiss.success.json",
    "requestId": "mock_req_recommend_dismiss",
    "fetchedAt": "2026-05-10T19:15:00Z"
  }
}
```

### Error States

#### 404 Listing Not Found

```json
{
  "error": {
    "code": "listing_not_found",
    "message": "Cannot generate recommendations for unknown listing stay_missing.",
    "details": {
      "listingId": "stay_missing"
    },
    "requestId": "mock_req_404_recommendation",
    "retryable": false
  }
}
```

#### 404 Recommendation Not Found

```json
{
  "error": {
    "code": "recommendation_not_found",
    "message": "Recommendation rec_missing does not exist for listing stay_1001.",
    "details": {
      "listingId": "stay_1001",
      "recommendationId": "rec_missing"
    },
    "requestId": "mock_req_404_recommendation_id",
    "retryable": false
  }
}
```

#### 500 Recommendation Engine Failure

```json
{
  "error": {
    "code": "recommendation_engine_failure",
    "message": "The mock recommendation engine failed while generating interventions.",
    "details": {
      "listingId": "stay_1001",
      "failedStage": "evidence_to_intervention_ranking",
      "fallbackBehavior": "show_cached_recommendations_if_available"
    },
    "requestId": "mock_req_500_recommendation",
    "retryable": true
  }
}
```

## 8. Swift Networking Guidance

### DTO Boundaries

The Swift networking layer should decode endpoint responses into DTOs, then map DTOs into domain models.

Recommended DTO groups:

- `ListingSummaryResponseDTO`
- `QualityReportResponseDTO`
- `HostReputationResponseDTO`
- `CreateQualitySignalRequestDTO`
- `CreateQualitySignalResponseDTO`
- `RecommendationInterventionRequestDTO`
- `RecommendationInterventionResponseDTO`
- `APIErrorResponseDTO`

### Fixture Transport Behavior

The fixture transport should support:

- Success fixture lookup by method and path.
- Error fixture lookup for 404 and 500 scenarios.
- Artificial latency for loading-state demos.
- Simulated offline failure for stale-while-refresh tests.
- Deterministic timestamps for stable snapshot tests.

### Cache Interaction

`GET /v1/listings/{id}/quality-report` should be the main stale-while-refresh route:

1. Repository reads cached SwiftData report.
2. Repository yields cached snapshot immediately if present.
3. Repository starts fixture refresh.
4. On success, repository upserts SwiftData and yields refreshed snapshot.
5. On failure, repository keeps cached data visible and attaches refresh error metadata.

### Required Mock Test Fixtures

At minimum, include fixtures for:

- `GET /v1/listings` success.
- `GET /v1/listings/{id}/quality-report` success.
- `GET /v1/listings/{id}/quality-report` 404.
- `GET /v1/listings/{id}/quality-report` 500.
- `GET /v1/hosts/{id}/reputation` success.
- `POST /v1/quality/signals` success and 422.
- `POST /v1/recommendations/interventions` suggest success.
- `POST /v1/recommendations/interventions` dismiss success.
- `POST /v1/recommendations/interventions` 500.
- `ListingQualityDetails` GraphQL success.
- `ListingQualityDetails` GraphQL 404.

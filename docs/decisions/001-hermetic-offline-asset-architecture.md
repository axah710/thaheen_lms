# ADR-001: Hermetic Offline Asset Architecture

- **Status**: Accepted
- **Date**: 2026-09-25
- **Author**: Engineering Team

---

## Context
Medical and health-sciences students frequently study in hospital wards, clinics, rural outposts, and transit environments with intermittent or non-existent cellular and Wi-Fi connectivity. Typical LMS platforms rely heavily on live HTTP streaming (HLS/DASH) and RESTful API backends, which fail completely when offline.

## Decision
Package all course metadata (`assets/data/courses.json`), course thumbnails (`assets/images/`), and educational videos (`assets/videos/*.mp4`) directly into the Flutter application bundle assets.
Enforce **0 remote network calls** across the entire lifecycle:
1. Data source (`CourseLocalDataSource`) loads exclusively via `AssetBundle`.
2. Videos initialize from local assets using `VideoPlayerController.asset()`.
3. An automated hermetic test (`test/unit/core/hermetic_offline_network_test.dart`) installs a custom `HttpOverrides` that fails closed if any `HttpClient` is instantiated.

## Consequences & Trade-offs
- **Pros**:
  - Instantaneous startup and zero-latency video buffering.
  - 100% reliable in airplane mode without internet access.
  - Zero server infrastructure costs and zero remote API failure points.
- **Cons & Mitigations**:
  - Increased application binary size (~35 MB for initial modules).
  - Tracked under [DEBT-20260926000000](../debt/20260926000000-bundled-video-asset-size.md) with long-term plan for modular local caching.

# Technical Debt Summary: Thaheen LMS

> **Living ledger of intentional trade-offs, temporary compromises, and architectural debt items.**

---

## Active Technical Debt Summary

| ID | Title | Category | Severity | First Identified | Related ADR | Payoff Trigger |
|---|---|---|---|---|---|---|
| [DEBT-20260926000000](../debt/20260926000000-bundled-video-asset-size.md) | Bundled Video Asset Packaging Size | Architecture / Storage | Medium | 2026-09-26 | ADR-001 | When course catalog expands beyond 5 courses |
| [DEBT-20260926000001](../debt/20260926000001-single-active-course-continue-watching.md) | Single Active Course "Continue Watching" Hero Card | UX / Application | Low | 2026-09-26 | ADR-004 | When users enroll in 3+ concurrent courses |

---

## Feature-Specific Debt Notes

### Course & Catalog
- **Bundled Asset Binary Footprint ([DEBT-20260926000000](../debt/20260926000000-bundled-video-asset-size.md))**:
  - All video MP4 files are currently embedded in the Flutter app bundle assets (`assets/videos/`).
  - This ensures 100% offline hermetic operation without requiring any network download phase.
  - *Trade-off*: Enlarges initial binary size (~30–40 MB). For large catalogs with dozens of medical courses, an on-demand local asset downloading/caching subsystem will be required.

### Player & Persistence
- **Single Latest Unfinished Lesson Resume ([DEBT-20260926000001](../debt/20260926000001-single-active-course-continue-watching.md))**:
  - The home catalog screen renders a single prominent "Continue Watching" hero card representing the most-recently accessed unfinished lesson across all courses.
  - *Trade-off*: If a student actively studies Anatomy 101 and Physiology 101 concurrently, only the most recent one is highlighted on the hero card (though individual course progress percentages and syllabus checkmarks persist accurately).

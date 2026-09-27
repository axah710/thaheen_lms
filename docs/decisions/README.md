# Architecture Decision Records (ADRs)

> **Authoritative ledger of technical decisions, rationales, and consequences for Thaheen LMS.**

---

| ADR | Title | Status | Date | Summary |
|---|---|---|---|---|
| [ADR-001](001-hermetic-offline-asset-architecture.md) | Hermetic Offline Asset Architecture | Accepted | 2026-09-25 | 100% offline operation via bundled assets with zero remote HTTP calls |
| [ADR-002](002-pure-dart-domain-layer-and-invariants.md) | Pure Dart Domain Layer and Invariants | Accepted | 2026-09-25 | Pure Dart entities, 90% auto-completion rule, sequential unlock rule |
| [ADR-003](003-arabic-first-rtl-ergonomics-and-unmirrored-media-controls.md) | Arabic-First RTL Ergonomics & Unmirrored Media Controls | Accepted | 2026-09-25 | TextDirection.rtl, unmirrored media icons, strictly Western Arabic digits |
| [ADR-004](004-durable-local-persistence-and-lifecycle-flushing.md) | Durable Local Persistence & Lifecycle Flushing | Accepted | 2026-09-25 | SharedPreferences envelope thaheen_progress_v1, 5s debounce, immediate lifecycle flush |
| [ADR-005](005-zero-red-screens-resilience-and-error-boundaries.md) | Zero Red Screens Fault Tolerance & Global Error Boundary | Accepted | 2026-09-25 | InPlayerErrorCard, EmptyCourseView, global ErrorWidget.builder replacement |
| [ADR-006](006-adaptive-flex-video-controls-layout.md) | Adaptive Flex Video Controls Layout | Accepted | 2026-09-25 | Inline trailing in RtlSeekBar, Expanded FittedBox center button, zero 16:9 overflow |

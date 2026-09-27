# Thaheen LMS — Mini Offline Learning Management System & Video Player

> **An Arabic-first, 100% offline learning platform for health-sciences students, engineered with Flutter and Clean Architecture.**

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC%2FCubit-green)](https://bloclibrary.dev)
[![Tests](https://img.shields.io/badge/Tests-102%20Passed%20(100%25)-success)](test/)
[![Offline](https://img.shields.io/badge/Network-100%25%20Hermetic%20Offline-orange)](test/unit/core/hermetic_offline_network_test.dart)

---

## Table of Contents

1. [How to Run](#1-how-to-run)
2. [Architecture & State-Management Choices](#2-architecture--state-management-choices)
3. [Trade-offs, Known Issues & What I'd Do With More Time](#3-trade-offs-known-issues--what-id-do-with-more-time)
4. [Time Spent](#4-time-spent)
5. [Directory Layout](#5-directory-layout)
6. [Test Suite & Quality Gates](#6-test-suite--quality-gates)

---

## 1. How to Run

### Prerequisites

| Tool | Minimum Version |
|---|---|
| Flutter SDK | `>=3.19.0 stable` |
| Dart SDK | `^3.13.0` |
| Xcode (iOS/macOS) | 15+ |
| Android SDK | API 26+ |

> **No `.env`, no backend, no API keys required.** Everything runs from bundled assets — courses JSON, section/lesson metadata, and short H.264 video clips are all included in the repository.

### Install & Launch

```bash
# 1. Clone
git clone https://github.com/axah710/thaheen_lms.git
cd thaheen_lms

# 2. Fetch dependencies
flutter pub get

# 3. Run (any connected device or simulator)
flutter run

# -- or target a specific platform explicitly --
flutter run -d ios
flutter run -d android
flutter run -d macos
```

The app starts immediately without network, accounts, or configuration.

### Run All Tests

```bash
# Full suite — 102 tests, all must pass
flutter test --no-pub

# Format & static analysis
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub

# Git hygiene
git diff --check
```

### Focused Test Commands

| Area | Command |
|---|---|
| **Hermetic Offline Guard** | `flutter test --no-pub test/unit/core/hermetic_offline_network_test.dart` |
| **90% Completion Rule** | `flutter test --no-pub test/unit/domain/lesson_completion_rule_test.dart` |
| **Sequential Unlock Rule** | `flutter test --no-pub test/unit/domain/sequential_unlock_rule_test.dart` |
| **Progress % Calculation** | `flutter test --no-pub test/unit/domain/progress_calculation_test.dart` |
| **Persistence & Lifecycle** | `flutter test --no-pub test/widget/persistence_lifecycle_test.dart` |
| **Arabic RTL Ergonomics** | `flutter test --no-pub test/widget/arabic_rtl_ergonomics_test.dart` |
| **Arabic Search** | `flutter test --no-pub test/unit/core/arabic_search_helper_test.dart` |
| **Zero Red Screens** | `flutter test --no-pub test/widget/zero_red_screens_resilience_test.dart` |

---

## 2. Architecture & State-Management Choices

### 2.1 Clean Architecture — Why?

The domain is small but the **rules are strict and precise**: a lesson completes at exactly 90%, sequential unlock crosses section boundaries, progress persists across app kills. These invariants needed a home that was:

- **Testable without Flutter or a device** — pure Dart, no widgets.
- **Replaceable at the edges** — the data layer (JSON bundling today, SQLite or API tomorrow) should not bleed into business rules.
- **Readable to a reviewer** — the rule lives in one file and the test lives in one file, in parallel directories.

The three-layer split I used:

```
domain/   — pure Dart entities + repository interfaces (no Flutter imports)
data/     — DTOs, JSON parsing, SharedPreferences adapters, repository impls
presentation/ — widgets + Cubits that glue domain to Flutter
```

The `domain/` layer has **zero dependencies** on Flutter widgets, platform plugins, or `dart:io`. Every entity is an immutable value object. Every business rule is a pure function. This made the 37 domain + core unit tests run in under 200 ms on any machine.

### 2.2 State Management: BLoC/Cubit — Why Cubit over Bloc?

I chose **Cubit** (from `flutter_bloc`) rather than full Bloc (explicit event classes) for this project. My reasoning:

| Factor | Bloc (Events) | Cubit (Methods) |
|---|---|---|
| Ceremony | High — one event class per intent | Low — direct method calls |
| Traceability | Full event-stream log | Same via `BlocObserver` |
| Fit for this scope | Over-engineered for 3 screens | Right-sized |
| Testing | `bloc_test` `act:` sends events | `bloc_test` `act:` calls methods |

The `LessonPlayerCubit` manages the most complex state: video controller lifecycle, debounced persistence, 90%-completion detection, playback speed cycling, controls auto-hide timer, and fullscreen mode — all as named methods that emit immutable `LessonPlayerState` subclasses. A reviewer can read `togglePlayPause()` and immediately understand the intent.

I would have chosen **Bloc with events** if the team were larger (events serialize over streams, making logging, replay, and analytics easier) or if user interactions were ambiguous (e.g., multiple event sources converging).

I would have chosen **Riverpod** if the app had a richer dependency graph where providers compose into each other, but for a three-screen app with a locator-style DI the constructor-injection + Cubit combination is simpler.

### 2.3 Local Persistence: SharedPreferences — Why?

The task explicitly permits SharedPreferences, Hive, Isar, or sqflite. My choice:

**`shared_preferences` with a typed envelope schema** (`thaheen_progress_v1`).

Reasons:
- **Zero-schema relational need.** Progress is keyed by `courseId` → map of `lessonId` → `{positionSec, isCompleted}`. A JSON blob under one key is sufficient and is human-readable in the device's storage inspector.
- **No code-generation.** Hive and Isar require `build_runner` and generated adapters. For a hermetic offline app with a fixed, two-entity data model this is overhead without benefit.
- **Proven write semantics.** The `setString` → `getString` round-trip is atomic on all Flutter platforms. I layered a **hybrid debounce + write-through buffer** on top: continuous updates are debounced by 5 seconds (preventing flash/EMMC wear from per-frame writes), but an immediate flush fires on pause, seek-release, 90%-completion, and all `AppLifecycleListener` transitions (`paused → inactive → hidden → detached`). This means the worst-case data loss window is 5 seconds during active playback, and effectively zero on any intentional or system-initiated pause.
- **Corruption recovery.** A `try/catch` around `jsonDecode` in the storage service resets the envelope and emits a localized Arabic SnackBar (`"تمت إعادة ضبط سجل التعلم المحلي لسلامة البيانات"`), keeping the app usable even after storage is corrupted by an OS-level disk-full event.

**When I'd switch:** If lessons ever had per-lesson notes (as the bonus suggested), a document store like Isar would pay off. If the course catalog became server-driven, a local relational schema (sqflite) with version migrations would be necessary.

### 2.4 Navigation: GoRouter — Why?

The task recommended `go_router` or Navigator 2.0. I used `go_router` with three named routes:

```
/                          → CourseListPage
/courses/:courseId          → CourseDetailsPage
/courses/:courseId/lessons/:lessonId  → LessonPlayerPage
```

GoRouter gives deep-link compatibility, typed path parameters, and back-stack correctness across all Flutter platforms (Android back button, iOS swipe, macOS keyboard shortcuts) with minimal boilerplate. Navigator 2.0 imperative push/pop would have worked fine too — the routing is simple — but GoRouter's declarative route map reads like a sitemap and is easier to extend.

### 2.5 Arabic-First RTL Design

The app is **unconditionally RTL with Arabic copy** — not a toggle. Every layout widget uses `EdgeInsetsDirectional` (start/end) instead of left/right so the Flutter engine mirrors padding automatically in RTL. The three deliberate **exceptions to mirroring**:

1. **Media playback controls** (`play ▶`, `pause ⏸`, seek bar) — time moves left-to-right universally. Mirroring these would confuse students about playback direction.
2. **Timestamps** — Western Arabic numerals (`0-9`) prevent misalignment in medical metrics.
3. **Back chevron** — points `→` (toward the reading direction) not `←`.

These are enforced by `matchTextDirection: false` on the relevant `Icon` widgets and verified by dedicated widget tests in `arabic_rtl_ergonomics_test.dart`.

### 2.6 Pedagogical Invariants (Domain Rules)

Three strict rules, each with its own test file:

**Rule 1 — 90% Auto-Completion** (`lesson_completion_rule_test.dart`):
```
isCompleted = positionSec >= (0.90 * durationSec).ceil()
```
- Completion is **irreversible and idempotent** — scrubbing backward preserves the completed badge.
- Division-by-zero guard: lessons with `durationSec == 0` never trigger completion.

**Rule 2 — Sequential Unlock** (`sequential_unlock_rule_test.dart`):
```
lesson[N] is unlocked iff lesson[N-1].isCompleted
lesson[0] in section[0] is always unlocked
```
The unlock check uses a flat global lesson index (`globalOrderIndex`) that crosses section boundaries deterministically.

**Rule 3 — Progress %** (`progress_calculation_test.dart`):
```
progress = clamp(round((completedCount / totalCount) * 100), 0, 100)
```
Courses with zero lessons return `0%` safely.

---

## 3. Trade-offs, Known Issues & What I'd Do With More Time

### Trade-offs Made

| Decision | Why | Cost |
|---|---|---|
| **Bundled offline assets** | Medical students study in zero-connectivity clinical environments. | Increases APK/IPA size by ~35 MB. Mitigated by short, H.264-optimized clips. |
| **SharedPreferences over Isar/Hive** | No build_runner overhead; JSON envelope is sufficient for the data model. | Less efficient for large datasets; would need migration if per-lesson notes are added. |
| **Cubit over Riverpod** | Simpler DI story with constructor injection; team is likely already on flutter_bloc. | Less compositional than Riverpod providers for complex cross-feature dependencies. |
| **No chewie wrapper** | Direct `video_player` + custom `CustomVideoControls` widget gives full control over RTL seek bar and Arabic UI. | More widget code to maintain than `chewie` out of the box. |
| **No per-lesson notes (bonus)** | Time was the constraint. | Students can't annotate lessons. |
| **No Arabic/English language switch (bonus)** | UI is unconditionally Arabic; a switch adds routing and locale complexity. | English-only device users cannot use the app. |
| **Playback speed not persisted across sessions** | Speed is a session preference held in `_sessionSpeed`; it resets on cubit close. | Students who always prefer 1.5x must re-select on each open. |

### Known Issues

1. **Playback speed is session-only.** `_sessionSpeed` is a field on `LessonPlayerCubit` and is not saved to `SharedPreferences`. It resets to `1.0x` whenever the player screen is popped and re-entered.

2. **Fullscreen is orientation-signal only.** The `isFullscreen` flag in `LessonPlayerState` triggers `SystemChrome.setPreferredOrientations(landscape)` but does not push a dedicated fullscreen route. On some Android devices the system navigation bar still occupies screen space in landscape.

3. **No video buffering indicator.** The `VideoPlayerController` provides a `buffered` list but the custom controls do not render a buffer bar — students may see a stall without visual feedback.

4. **Single-device progress.** Progress is local only. If a student switches devices, they start from zero.

5. **Asset path is hardcoded.** Video paths are relative strings in `courses.json`. A path typo causes `LessonPlayerError` (which is handled gracefully), but there is no build-time validation of asset existence.

### What I'd Do With More Time

**High-impact, low-effort:**
- Persist `_sessionSpeed` in `SharedPreferences` under a `thaheen_settings_v1` key. One `setDouble` call in `cyclePlaybackSpeed()`.
- Add a `LinearProgressIndicator` driven by `controller.value.buffered` for honest buffering feedback.
- Push a dedicated `FullscreenPlayerRoute` with `WillPopScope` and `SystemChrome` restoration for pixel-perfect fullscreen on Android.

**Medium-effort:**
- **Per-lesson notes** using Isar or SQLite. The domain interface (`IProgressRepository`) is the natural extension point — add a `saveLessonNote(lessonId, note)` method without touching Cubit or UI.
- **Arabic/English locale switch.** Add `flutter_localizations` + two ARB files, a `LocaleCubit`, and persist the choice in settings.
- **Offline-first course catalog sync.** Keep a bundle as the seed, fetch a remote JSON update when online, merge with a version field, persist to local storage. The repository interface already abstracts the data source.

**Architectural:**
- **Replace SharedPreferences with Isar** for the progress store if the data model grows (e.g., notes, bookmarks, quiz answers). Isar provides schema migrations and typed queries without the code-gen overhead of Hive.
- **Extract a `VideoPlayerService`** that wraps `VideoPlayerController` behind a testable interface. Currently `LessonPlayerCubit` accepts a `controllerFactory` function for injection — this is sufficient for tests but a proper interface would be cleaner for mocking.
- **Add Golden tests** for RTL layout correctness. The current widget tests assert Finder presence and Semantics; golden snapshots would catch regressions in padding, chevron direction, and seek bar layout across screen sizes.
- **CI pipeline** — a GitHub Actions workflow running `dart format`, `flutter analyze`, and `flutter test` on every PR.

---

## 4. Time Spent

**~90 minutes**, distributed roughly as:

| Phase | Time |
|---|---|
| Domain modeling — entities, invariants, repository interfaces | ~15 min |
| Data layer — JSON parsing, SharedPreferences envelope, debounce logic | ~10 min |
| Application layer — CourseListCubit, CourseDetailsCubit, LessonPlayerCubit | ~20 min |
| Presentation — 3 screens, custom video controls, RTL seek bar, error cards | ~20 min |
| Tests — 102 unit + widget tests across all layers | ~15 min |
| Bonus — Arabic search + normalization engine | ~10 min |

The biggest time sink was the `LessonPlayerCubit` — managing controller lifecycle, debounce timers, completion detection, and fullscreen state in a single Cubit while keeping it hermetically testable (via the `controllerFactory` injection point) required careful ordering of async operations.

The second largest was Arabic RTL ergonomics — specifically deciding which controls to mirror and which to preserve, and writing the corresponding tests to lock that decision in.

I deliberately stayed within the time box. Features I deprioritized are documented in the trade-offs above.

---

## 5. Directory Layout

```text
lib/
├── app/
│   ├── app.dart                   # ThaheenApp widget — RTL Directionality + ThemeData
│   ├── error_boundary.dart        # Global ErrorWidget.builder override (Zero Red Screens)
│   ├── router.dart                # AppRouter with declarative GoRouter navigation
│   └── theme.dart                 # Color palette: Deep Teal, Emerald, Warm Amber, Slate
├── core/
│   ├── errors/
│   │   └── failures.dart          # Domain Failure hierarchy (NotFound, Storage, Parsing)
│   ├── storage/
│   │   └── local_storage_service.dart # Durable SharedPreferences persistence service
│   └── utils/
│       ├── arabic_search_helper.dart  # Pure Dart Arabic normalization (tashkeel, alef, taa marbuta)
│       └── duration_formatter.dart    # Western Arabic timestamp formatting
├── features/
│   ├── course/
│   │   ├── application/
│   │   │   ├── course_details_cubit.dart
│   │   │   ├── course_list_cubit.dart
│   │   │   └── models/continue_watching_item.dart
│   │   ├── data/
│   │   │   ├── data_sources/course_local_data_source.dart  # Reads bundled courses.json
│   │   │   ├── models/course_dto.dart                      # JSON ↔ entity mapping
│   │   │   └── repositories/course_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/course.dart, section.dart, lesson.dart, continue_watching_item.dart
│   │   │   └── repositories/i_course_repository.dart
│   │   └── presentation/
│   │       ├── course_details_page.dart
│   │       ├── course_list_page.dart
│   │       └── widgets/  — CourseCard, SectionCard, CourseSearchBar, EmptySearchView, …
│   └── player/
│       ├── application/
│       │   └── lesson_player_cubit.dart   # Core video+progress state machine
│       ├── data/
│       │   ├── data_sources/progress_local_data_source.dart
│       │   ├── models/progress_envelope_dto.dart, lesson_progress_dto.dart
│       │   └── repositories/progress_repository_impl.dart
│       ├── domain/
│       │   ├── entities/course_progress.dart, lesson_progress.dart, lesson_status.dart
│       │   └── repositories/i_progress_repository.dart
│       └── presentation/
│           ├── lesson_player_page.dart
│           └── widgets/ — CustomVideoControls, RtlSeekBar, InPlayerErrorCard, …
└── main.dart                      # Bootstrap: error boundary init → GoRouter → runApp
```

```text
test/
├── helpers/
│   └── fake_video_player_platform.dart   # Hermetic video platform stub
├── unit/
│   ├── application/                      # Cubit state-machine tests (bloc_test)
│   ├── core/                             # Storage, offline network, Arabic search tests
│   ├── data/                             # DTO parsing and repository tests
│   └── domain/                           # Pure business rule tests (90%, unlock, progress%)
└── widget/                               # RTL, persistence, player screen, zero-red-screens
```

---

## 6. Architecture Decisions — ADR Summary

| Decision | Rationale | Trade-off |
|---|---|---|
| **Clean Architecture (3 layers)** | Domain rules are precise and independently testable. | Requires DTO↔entity mapping boilerplate. |
| **Cubit over full Bloc** | Right-sized for 3 screens; less ceremony, same observability via BlocObserver. | Less idiomatic for event-replay / analytics tracking. |
| **SharedPreferences (debounced + write-through)** | No code-gen; JSON envelope fits the data model; 5s debounce protects flash storage. | Session-kill window of up to 5 s; not suitable if notes/bookmarks are added. |
| **GoRouter** | Declarative routes, deep-link ready, back-stack correct on all platforms. | Minor overhead for a 3-screen app; Navigator.push would have been sufficient. |
| **Bundled offline assets** | Medical students study in zero-connectivity clinical environments. | ~35 MB APK/IPA size increase; no OTA content updates. |
| **Direct video_player (no chewie)** | Full control over RTL seek bar and Arabic control layout. | More custom widget code than chewie would require. |
| **Unmirrored media controls in RTL** | Time is a universal physical direction; mirroring confuses playback progress. | Requires explicit `matchTextDirection: false` and test coverage to prevent regression. |
| **Fail-closed global error boundary** | Medical students cannot be shown a red debug screen mid-study. | Swallows widget exceptions into an Arabic recovery card — harder to surface in production. |

---

## 7. License & Credits

Developed as a screening task for Thaheen — an Arabic-first health-sciences learning platform. All sample medical content follows standardized educational curricula. Video clips are royalty-free.

# Thaheen LMS — Mini Offline Learning Management System & Video Player

> **An Arabic-first, 100% offline learning platform for health-sciences students, engineered with Flutter and Clean Architecture.**

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC%2FCubit-green)](https://bloclibrary.dev)
[![Tests](https://img.shields.io/badge/Tests-86%20Passed%20(100%25)-success)](test/)
[![Offline](https://img.shields.io/badge/Network-100%25%20Hermetic%20Offline-orange)](test/unit/core/hermetic_offline_network_test.dart)

---

## 1. Overview & Architectural Vision

**Thaheen LMS** is designed specifically for medical and health-sciences students who study demanding curricula in clinical environments with unreliable or non-existent internet connectivity. The application operates in **100% hermetic offline mode**—all course curricula, structured sections, lessons, metadata, and high-definition video assets are packaged directly into the application bundle.

The architecture enforces strict separation of concerns, deterministic domain invariants, right-to-left (RTL) ergonomics, durable background persistence, and a resilient "Zero Red Screens" fault-tolerance guarantee.

---

## 2. Core Architectural Principles & Invariants

### 2.1 Pure Dart Domain Layer (Clean Architecture)
The domain layer (`lib/features/course/domain/` and `lib/features/player/domain/`) is written in **pure Dart**:
- Zero dependencies on Flutter UI, widgets, rendering, or third-party platform plugins.
- Business rules are expressed as deterministic, mathematical pure functions and immutable entities (`Course`, `Section`, `Lesson`, `CourseProgress`, `LessonProgress`).
- Errors and business outcomes are encapsulated using typed `Either<Failure, T>` return signatures.

### 2.2 Pedagogical Rules & Domain Invariants
1. **The Irreversible 90% Auto-Completion Rule** ($\ge 0.90 \times \text{durationSec}$):
   - A lesson transitions to `Completed` if and only if playback reaches or exceeds $90\%$ of total lesson duration (`positionSec >= (0.90 * durationSec).ceil()`).
   - Completion is **irreversible and idempotent**: scrubbing backward after reaching 90% preserves the completed state.
   - Safe guards prevent division-by-zero or false triggers when durations are invalid or zero.
2. **Sequential Unlock Rule Across Sections**:
   - Lesson 1 in Section 1 is unlocked by default for any enrolled course.
   - For all subsequent lessons ($N > 1$), Lesson $N$ is unlocked if and only if Lesson $N-1$ has achieved `Completed` status.
   - Unlocking seamlessly crosses section boundaries according to the global syllabus order.
3. **Deterministic Progress Calculation**:
   - Course progress percentage is calculated as:
     $$\text{Progress} = \text{clamp}\left(\left\lfloor \frac{\text{Completed Lessons}}{\text{Total Lessons}} \times 100 \right\rfloor, 0, 100\right)$$
   - Courses with 0 lessons safely return $0\%$ progress without throwing `NaN` or unhandled exceptions.

### 2.3 Arabic-First Right-to-Left (RTL) Ergonomics
- The UI defaults unconditionally to `TextDirection.rtl` with Arabic copy.
- Directional layout uses `EdgeInsetsDirectional` (start/end) to maintain symmetrical gutters and margins.
- **Directional Navigation Chevrons**: Navigational back and forward chevrons point in the natural reading direction ($\rightarrow$ for back).
- **Unmirrored Media Controls**: Universal physical time conventions are preserved—media playback controls (play `▶`, pause `⏸`, forward $+10\text{s}$, rewind $-10\text{s}$) remain unmirrored.
- **Western Arabic Numerals (`0-9`)**: Timestamps, durations, speeds, and percentages use clean Western Arabic digits to prevent misalignment in medical and technical metrics.

### 2.4 Durable Local Persistence & App Lifecycle Resumption
- All progress records are stored locally via `SharedPreferences` in an envelope schema under key `thaheen_progress_v1`.
- **Hybrid Debouncing & Write-Through Buffer**:
  - Continuous playback updates are debounced by **5 seconds** to prevent excessive disk/flash I/O.
  - An immediate write-through buffer flush is triggered upon **pause**, **seek release**, **90% completion threshold crossing**, and across all Flutter `AppLifecycleListener` transitions (`paused`, `inactive`, `hidden`, `detached`).
- **Resilient Cold Restarts**:
  - Saved timestamps survive app termination and process evictions.
  - The home screen renders a **"Continue Watching" (متابعة التعلم)** hero card displaying the last-watched unfinished lesson, resuming playback within $<100\text{ms}$.
  - Storage corruption is detected, safely isolated, and reset to an empty state accompanied by an Arabic notification SnackBar: `"تمت إعادة ضبط سجل التعلم المحلي لسلامة البيانات"`.

### 2.5 Zero Red Screens & Fault Tolerance
- **In-Player Media Error Fallback**: If a video asset is missing, corrupted, or unsupported, `LessonPlayerPage` intercepts the error and displays a custom `InPlayerErrorCard` with Arabic explanation, a Retry action, and a Return to Course navigation button.
- **Empty Course Fallback**: Courses with zero lessons or sections display an `EmptyCourseView` without layout collapse.
- **Global Error Boundary**: A top-level error boundary overrides `ErrorWidget.builder` to catch any unhandled rendering exceptions, completely preventing the Flutter "red screen of death" in production.

---

## 3. Directory Layout

```text
lib/
├── app/
│   ├── app.dart                   # ThaheenApp widget with RTL Directionality & ThemeData
│   ├── error_boundary.dart        # Global ErrorWidget.builder replacement
│   ├── router.dart                # AppRouter with declarative GoRouter navigation
│   └── theme.dart                 # Color palette (Deep Teal, Emerald, Warm Amber, Slate)
├── core/
│   ├── errors/
│   │   └── failures.dart          # Domain Failure hierarchy (NotFound, Storage, Parsing)
│   └── storage/
│       └── local_storage_service.dart # Durable SharedPreferences persistence service
├── features/
│   ├── course/
│   │   ├── application/
│   │   │   ├── course_details_cubit.dart
│   │   │   ├── course_list_cubit.dart
│   │   │   └── models/continue_watching_item.dart
│   │   ├── data/
│   │   │   ├── data_sources/course_local_data_source.dart
│   │   │   ├── models/course_dto.dart
│   │   │   └── repositories/course_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/course.dart, section.dart, lesson.dart, continue_watching_item.dart
│   │   │   └── repositories/i_course_repository.dart
│   │   └── presentation/
│   │       ├── course_details_page.dart
│   │       ├── course_list_page.dart
│   │       └── widgets/ (CourseCard, SectionCard, LessonListTile, EmptyCourseView, etc.)
│   └── player/
│       ├── application/
│       │   └── lesson_player_cubit.dart
│       ├── data/
│       │   ├── data_sources/progress_local_data_source.dart
│       │   ├── models/progress_envelope_dto.dart, lesson_progress_dto.dart
│       │   └── repositories/progress_repository_impl.dart
│       ├── domain/
│       │   ├── entities/course_progress.dart, lesson_progress.dart, lesson_status.dart
│       │   └── repositories/i_progress_repository.dart
│       └── presentation/
│           ├── lesson_player_page.dart
│           └── widgets/ (CustomVideoControls, RtlSeekBar, InPlayerErrorCard, etc.)
└── main.dart                      # Bootstrap sequence with error boundary initialization
```

---

## 4. Setup & Running

### 4.1 Prerequisites
- **Flutter SDK**: `>=3.19.0`
- **Dart SDK**: `>=3.3.0`
- Compatible with iOS, Android, and macOS desktop.

### 4.2 Installation & Launch
```bash
# 1. Clone repository
git clone https://github.com/example/thaheen_lms.git
cd thaheen_lms

# 2. Fetch offline dependencies
flutter pub get

# 3. Run application (Target: Android, iOS, or macOS desktop)
flutter run
```

---

## 5. Verification & Quality Gates

Every code change must pass the repository's strict quality gate sequence:

```bash
# 1. Format check (ensures clean, standardized Dart formatting)
dart format --output=none --set-exit-if-changed .

# 2. Static Analysis (zero warnings, zero errors enforced)
flutter analyze --no-pub

# 3. Full Test Suite Execution (Unit, Widget, and Lifecycle tests)
flutter test --no-pub

# 4. Whitespace and Git Hygiene check
git diff --check
```

### 5.1 Focused Test Commands
| Area | Command | Purpose |
|---|---|---|
| **Hermetic Offline Operation** | `flutter test --no-pub test/unit/core/hermetic_offline_network_test.dart` | Asserts 0 HTTP/socket calls via `HttpOverrides` |
| **90% Completion Rule** | `flutter test --no-pub test/unit/domain/lesson_completion_rule_test.dart` | Tests 89.9% guard, 90% trigger, and idempotence |
| **Sequential Unlock Rule** | `flutter test --no-pub test/unit/domain/sequential_unlock_rule_test.dart` | Tests L1 unlock, L2+ lock, and section transitions |
| **Progress Calculations** | `flutter test --no-pub test/unit/domain/progress_calculation_test.dart` | Tests progress percentage, clamping, and zero-length safety |
| **Persistence & Lifecycle** | `flutter test --no-pub test/widget/persistence_lifecycle_test.dart` | Tests cold restarts, `AppLifecycleListener`, corruption recovery |
| **Arabic RTL Ergonomics** | `flutter test --no-pub test/widget/arabic_rtl_ergonomics_test.dart` | Tests RTL margins, unmirrored controls, Western numerals |
| **Zero Red Screens Resilience** | `flutter test --no-pub test/widget/zero_red_screens_resilience_test.dart` | Tests corrupt video error card and global error boundary |

---

## 6. Architecture Decisions & Trade-offs (ADRs)

| Decision | Rationale | Trade-off / Mitigations |
|---|---|---|
| **Bundled Offline Assets** | Health-sciences students often study in zero-connectivity clinical wards. | Increases initial package size (<40 MB). Mitigated with short, optimized H.264 clips. |
| **Hybrid Persistence (5s Debounce + Write-Through)** | Frequent disk I/O on every frame/second causes flash wear and battery drain. | Risk of lost progress on sudden OS kill. Mitigated by immediate flush on `paused`, `inactive`, `hidden`, and `detached`. |
| **Pure Dart Domain Invariants** | Isolating business logic from Flutter makes tests deterministic, fast (<2s), and codec-independent. | Requires mapping between domain models and DTOs. |
| **Unmirrored Media Controls in RTL** | Arabic readers perceive video progress and playback controls through universal physical time conventions. | Requires explicit `matchTextDirection: false` configuration on playback icons. |
| **Fail-Closed Global Error Boundary** | Prevents confusing crashes and red screens for medical students during study sessions. | Overrides Flutter's default error screen with an informative Arabic recovery dialog. |

---

## 7. License & Credits

Developed with precision for medical learning excellence. All medical terminology and pedagogical structures comply with modern health-sciences educational standards.

# Key Facts & Project Reference: Thaheen LMS

> **Authoritative reference for configurations, keys, domain rules, test commands, and quality gates.**

---

## 1. Environment & Technical Stack

| Specification | Value / Detail |
|---|---|
| **App Name** | `thaheen_lms` (Thaheen Mini Offline LMS) |
| **Target Audience** | Medical and health-sciences students |
| **Flutter SDK** | `>=3.19.0` (stable) |
| **Dart SDK** | `^3.13.0` (null-safe) |
| **Target Platforms** | Android (API 21+), iOS (iOS 12+), macOS desktop |
| **State Management** | BLoC / Cubit (`flutter_bloc: ^8.1.3`) |
| **Functional Error Handling** | Either / Left / Right (`either_dart: ^1.0.0`) |
| **Local Storage** | SharedPreferences (`shared_preferences: ^2.2.2`) |
| **Video Playback** | Video Player (`video_player: ^2.8.2`) |
| **Declarative Router** | GoRouter (`go_router: ^13.2.0`) |

---

## 2. Storage & Persistence Contracts

- **Envelope Key**: `thaheen_progress_v1` (stored as serialized JSON string in `SharedPreferences`).
- **Schema Version**: `1` (integer field in envelope).
- **Format**:
  ```json
  {
    "schemaVersion": 1,
    "records": {
      "l1": {
        "lessonId": "l1",
        "courseId": "anatomy-101",
        "lastPositionSec": 42,
        "isCompleted": false,
        "lastAccessedAt": "2026-09-25T20:30:00.000Z"
      }
    }
  }
  ```
- **Debounce Window**: 5.0 seconds for continuous playback updates.
- **Immediate Write-Through Triggers**:
  - Video pause (`togglePlayPause()`).
  - Seek bar scrub completion (`seekTo()`).
  - 90% auto-completion threshold crossing.
  - Page exit / back navigation (`pop()`).
  - Flutter lifecycle state transitions: `paused`, `inactive`, `hidden`, and `detached`.
- **Corrupted Data Recovery**:
  - Malformed JSON automatically resets to `ProgressEnvelopeDto.empty()`.
  - Storage is wiped clean to prevent repeat parsing crashes.
  - Arabic SnackBar notification emitted: `"تمت إعادة ضبط سجل التعلم المحلي لسلامة البيانات"`.

---

## 3. Pedagogical Domain Invariants

- **90% Auto-Completion**:
  $$\text{isCompleted} \iff \text{positionSec} \ge \lceil 0.90 \times \text{durationSec} \rceil$$
  - Irreversible: scrubbing backward after crossing 90% preserves `isCompleted = true`.
  - Replay-safe: restarting a completed lesson from `00:00` preserves completed status.
  - Duration safety: $\le 0$ duration clamped safely to prevent division-by-zero or premature triggers.
- **Sequential Unlocking**:
  - Lesson 1 in Section 1 is unlocked by default (`LessonStatus.notStarted`).
  - Lesson $N$ ($N > 1$) is locked (`LessonStatus.locked`) until Lesson $N-1$ is `LessonStatus.completed`.
  - Unlocking seamlessly crosses section boundaries according to `globalOrderIndex`.
- **Progress Percentage Math**:
  $$\text{Progress} = \text{clamp}\left(\text{round}\left( \frac{\text{Completed Lessons}}{\text{Total Lessons}} \times 100 \right), 0, 100\right)$$
  - Empty courses (0 lessons) evaluate strictly to $0\%$.

---

## 4. Typography & RTL Ergonomics

- **Primary Locale**: Arabic (`ar`).
- **Directionality**: Global `TextDirection.rtl`.
- **Numerals**: Strictly Western Arabic (`0-9`) across all timestamps (`00:42`), speeds (`1.25x`), and percentages (`33%`). Eastern Arabic digits (`٠-٩`) are banned to avoid medical/metric ambiguity.
- **Unmirrored Media Controls**: Universal physical time conventions are enforced (`matchTextDirection: false` on `play_arrow_rounded` and `pause_rounded`).
- **Directional Navigation Icons**: Directional chevrons point in natural reading direction (`matchTextDirection: true` on `arrow_back_rounded` $\rightarrow$ points right in RTL).

---

## 5. Asset Catalog & Bundling Contracts

All assets reside in the application bundle (zero remote HTTP requests):

```text
assets/
├── data/
│   └── courses.json              # Bundled courses & syllabus catalog (UTF-8, Arabic)
├── videos/
│   ├── anatomy_intro.mp4         # Short MP4 clip (<10 MB, H.264 / AAC)
│   ├── anatomy_bones.mp4         # Short MP4 clip (<10 MB, H.264 / AAC)
│   ├── physiology_intro.mp4      # Short MP4 clip (<10 MB, H.264 / AAC)
│   └── corrupt_lesson.mp4        # Corrupted byte fixture for error resilience
└── images/
    ├── anatomy.png               # Anatomy 101 thumbnail
    ├── physiology.png            # Physiology 101 thumbnail
    └── placeholder.png           # Fallback image thumbnail
```

---

## 6. Arabic Search & Normalization Engine

- **Normalization Utility**: `ArabicSearchHelper` (`lib/core/utils/arabic_search_helper.dart`).
- **Linguistic Rules**:
  - **Diacritics (Tashkeel)**: Strips `[\u064B-\u065F\u0670]` (Tanween, Fathah, Dammah, Kasrah, Shaddah, Sukun, superscript Alef).
  - **Tatweel (Kashida)**: Strips `\u0640`.
  - **Alef Variants**: Unifies `[أإآٱ]` to bare Alef `ا`.
  - **Taa Marbuta**: Normalizes `ة` to `ه`.
  - **Alef Maqsura**: Normalizes `ى` to `ي`.
  - **Casing & Trimming**: Lowercases Latin characters (acronyms) and trims whitespace.
- **Search Scope**: Evaluates matches across `course.title` and `course.instructor`.
- **Hero Card State**: Suppressed when `isSearching = true` to maximize search result visibility.
- **Empty State**: Renders `EmptySearchView` when zero courses match with single-tap catalog reset.

---

## 7. Authoritative Quality Gate Commands

```bash
# 1. Format check
dart format --output=none --set-exit-if-changed .

# 2. Static analysis
flutter analyze --no-pub

# 3. Hermetic offline network enforcement test
flutter test --no-pub test/unit/core/hermetic_offline_network_test.dart

# 4. Full test suite execution (102 tests)
flutter test --no-pub

# 5. Git diff whitespace hygiene check
git diff --check
```

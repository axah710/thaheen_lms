# ADR-007: Course Search with Arabic Normalization and In-Memory Filtering

- **Status**: Accepted
- **Date**: 2026-09-27
- **Author**: Engineering Team

---

## Context

Health-sciences students navigating the offline course catalog require fast, low-friction discovery of specific subjects, modules, and instructors. Prior to this decision, the course catalog presented an unindexed, sequential list with the following architectural and usability constraints:

1. **Clean Architecture Layer Inversion**: The `ContinueWatchingItem` model was situated in the Application layer (`lib/features/course/application/models/continue_watching_item.dart`). However, domain repository contract `IProgressRepository.resolveContinueWatching()` and data repository `ProgressRepositoryImpl` directly imported and returned this type. This violated Clean Architecture dependency direction, where the Domain layer must remain pure and free from outward dependencies on Application or Presentation constructs.
2. **Arabic Orthographic & Diacritic Search Fragility**: Arabic medical curricula feature vocalized titles with Tashkeel (e.g., `مُقَدِّمَةٌ فِي التَّشْرِيحِ`), typographical tatweel (e.g., `تــــشريـــح`), and interchangeable letter forms (`أ`/`إ`/`آ`/`ٱ` vs `ا`, `ة` vs `ه`, `ى` vs `ي`). Mobile keyboards rarely input diacritics. Naïve string containment (`String.contains`) causes unacceptable false negatives and user friction.
3. **Hermetic Offline Environment**: In compliance with ADR-001, the application operates 100% offline without remote search APIs or network indexers. Catalog searches must execute deterministically on-device without latency or battery drain.
4. **UI Ergonomics & Zero Red Screens**: Active searches must adhere to Arabic RTL layout principles (ADR-003) and provide graceful, non-crashing empty states with clear recovery actions (ADR-005).

## Decision

Implement an in-memory, reactive search architecture paired with pure Dart Arabic normalization and clean domain separation:

1. **Domain Layer Normalization (`ContinueWatchingItem`)**:
   - Move `ContinueWatchingItem` to `lib/features/course/domain/entities/continue_watching_item.dart` as an immutable, pure Dart entity extending `Equatable`.
   - Provide domain-level progress calculation (`progressRatio = (progress.lastPositionSec / lesson.durationSec).clamp(0.0, 1.0)`).
   - Re-export the entity from `lib/features/course/application/models/continue_watching_item.dart` to maintain backwards compatibility.
   - Refactor `IProgressRepository` and `ProgressRepositoryImpl` to depend strictly on the domain entity, restoring inward Clean Architecture dependency flow.

2. **Pure Dart Linguistic Normalization (`ArabicSearchHelper`)**:
   - Create a stateless, pure Dart utility `ArabicSearchHelper` under `lib/core/utils/` with zero Flutter framework dependencies:
     - **Tashkeel Stripping**: `RegExp(r'[\u064B-\u065F\u0670]')` removes Fatha, Damma, Kasra, Sukun, Tanween, Shadda, and superscript Alef.
     - **Tatweel Removal**: `RegExp(r'\u0640')` strips typographical elongation (kashida).
     - **Alef Unification**: `RegExp(r'[أإآٱ]')` collapses all hamzated forms to bare Alef (`ا`).
     - **Orthographic Harmonization**: Normalizes Taa Marbuta (`ة` $\to$ `ه`) and Alef Maqsura (`ى` $\to$ `ي`).
     - **Case-Insensitive Latin Matching**: Lowercases text to support medical acronyms and English terms (e.g., "ECG", "Anatomy").
     - **Symmetric Matching**: `matches(source, query)` normalizes both the target attribute and the user query before substring evaluation, returning `true` for empty/whitespace queries.

3. **Reactive In-Memory Catalog Filtering**:
   - Maintain the immutable master list of `courses` in `CourseListLoaded`.
   - Add `searchQuery` to `CourseListLoaded` alongside a computed property `filteredCourses` that evaluates `ArabicSearchHelper.matches()` against both `course.title` and `course.instructor`.
   - Expose `CourseListCubit.search(String query)` and `CourseListCubit.clearSearch()` using safe emission (`emitSafe`) guarding against post-closure exceptions.
   - Execute filtering synchronously in memory ($O(N)$), yielding instant, sub-millisecond updates without asynchronous debounce lag or disk I/O.

4. **RTL Ergonomic & Fault-Tolerant UI**:
   - **`CourseSearchBar`**: Persistent top search bar with `TextDirection.rtl`, Arabic placeholder text (`ابحث عن دورة أو محاضر...`), search icon prefix, and a reactive `ValueListenableBuilder` clear button suffix (`Icons.clear_rounded`).
   - **Contextual Hero Card Suppression**: Suppress `ContinueWatchingCard` during active search (`isSearching == true`) to maximize screen space for search results, and dynamically update the header to `'نتائج البحث (${filteredCourses.length})'`.
   - **`EmptySearchView`**: Display a polite Arabic zero-match card quoting the search query with an explicit "مسح البحث وتصفح الكل" action button to restore the catalog in one tap.

5. **Test Suite Verification**:
   - Expand the automated test suite from 86 to 102 tests (+16 tests):
     - Unit tests for all normalization rules and edge cases in `test/unit/core/arabic_search_helper_test.dart`.
     - Cubit filtering and state transition tests in `test/unit/application/course_list_cubit_test.dart`.
     - Widget tests for input dispatch, search-active UI layout changes, and empty-state recovery in `test/widget/course_list_screen_test.dart`.

## Consequences & Trade-offs

- **Pros**:
  - **High Search Recall**: Students can locate courses and instructors regardless of diacritics, keyboard auto-corrections, or kashida styling.
  - **Architectural Rigor**: Clean Architecture dependency inversion is resolved; Domain and Data layers depend only on pure Dart domain entities.
  - **Instantaneous Responsiveness**: Zero keystroke debounce latency; filtering runs synchronously in-memory on the UI isolate with zero disk or network overhead.
  - **Resilient Fallback UX**: Clear feedback and single-tap recovery when queries yield no results, preventing dead-ends.
  - **Hermetic Testing**: Fast, deterministic unit and widget tests running in milliseconds without platform channel or database mocks.

- **Cons & Mitigations**:
  - **Linear Complexity $O(N)$**: Filtering scans the course list linearly. *Mitigation*: For the local offline catalog (<500 courses), linear filtering completes in under 1 millisecond. An indexed inverted token map can be introduced if the catalog expands by orders of magnitude.
  - **Scope Limitation**: Search currently filters by course title and instructor name. *Mitigation*: The normalization engine in `ArabicSearchHelper` can be reused to index section titles, lesson titles, or tags as syllabus search requirements evolve.

## Alternatives Considered

### 1. Naïve Substring Matching (`String.contains`) without Normalization
- **Description**: Rely directly on standard Dart string operations (`source.toLowerCase().contains(query.toLowerCase())`).
- **Pros**: Zero utility code; trivial implementation.
- **Cons**: High failure rate in Arabic text. Queries omitting Tashkeel fail against vocalized titles; differing Alef forms or Taa Marbuta endings produce false negatives, creating frustrating user dead-ends.

### 2. SQLite / FTS5 (Full-Text Search) Local Database Engine
- **Description**: Introduce `sqflite` or `drift` with SQLite's FTS5 extension to perform database-level tokenization and search queries.
- **Pros**: Scales to tens of thousands of courses; supports BM25 ranking and phonetic stemming.
- **Cons**: Introduces heavy native dependencies, increases binary footprint, breaks the hermetic JSON asset architecture (ADR-001), and requires custom SQLite Arabic tokenizers that add maintenance overhead on mobile platforms.

### 3. Asynchronous Debounced Search via Streams in Cubit
- **Description**: Debounce keystroke events by 300ms using RxDart or timer buffers prior to filtering.
- **Pros**: Conserves CPU cycles when searching large datasets or executing remote API queries.
- **Cons**: Introduces artificial latency and noticeable typing stutter for small-to-moderate local catalogs where in-memory filtering executes in <1ms. Synchronous reactive state emission provides a superior, lag-free experience.

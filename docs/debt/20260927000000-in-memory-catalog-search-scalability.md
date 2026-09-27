---
id: DEBT-20260927000000
title: "In-Memory Catalog Search & Arabic Filtering Scalability"
category: "Technical Debt — Architecture / Performance"
severity: "Medium"
first_identified: "2026-09-27"
related_adrs: ["ADR-001", "ADR-002", "ADR-003", "ADR-007"]
payoff_trigger: "When course catalog exceeds 100 courses or full-text lesson transcript search is introduced"
---

# In-Memory Catalog Search & Arabic Filtering Scalability

## Description
Course catalog search (`CourseListLoaded.filteredCourses`) currently executes as an un-debounced, in-memory linear filter (`Iterable.where`) across `course.title` and `course.instructor` inside the Flutter UI isolate on every keystroke. For each candidate course, `ArabicSearchHelper.matches` applies multi-pass regular expression substitutions (tashkeel stripping, tatweel removal, alef unification, taa-marbuta/alef-maqsura mapping, and lowercasing) to both the source strings and query.

## Locations
- `lib/core/utils/arabic_search_helper.dart`
- `lib/features/course/application/course_list_state.dart` (`filteredCourses` getter)
- `lib/features/course/application/course_list_cubit.dart` (`search`, `clearSearch`)
- `lib/features/course/presentation/course_list_page.dart`
- `lib/features/course/presentation/widgets/course_search_bar.dart`

## Why This Exists
Fulfills the bonus search requirement with zero external database dependencies, preserving **ADR-001 (100% Hermetic Offline Architecture)** and **ADR-002 (Pure Dart Domain Layer)**. For the current bundled medical catalog (<50 courses), in-memory filtering executes synchronously in memory without disk or network I/O, introduces no asynchronous race conditions, and requires no database schema migrations.

## Trade-Off & Failure Modes under Growth
1. **Garbage Collection (GC) Pressure**: Re-normalizing course strings and creating intermediate substrings on every keystroke causes GC allocations. At 100+ courses, rapid typing on low-tier mobile devices will trigger frame jank.
2. **Transcript / Deep Syllabus Scalability ($O(N \times L)$ Complexity)**: If search expands to full-text lesson audio/video transcripts, section outlines, or medical glossaries (10KB–100KB per course), scanning unindexed text in-memory on the main isolate will block the UI thread and violate the 16ms frame budget.
3. **Morphological Limitations**: Current normalization unifies character shapes but lacks Arabic tokenization, prefix detachment (e.g., stripping the definite article 'ال', conjunctions 'و/ف', prepositions 'ب/ل'), and root-based stemming.

## Correct Long-Term Fix
1. **SQLite FTS5 Integration**: Migrate persistent local metadata to an embedded SQLite database with the `FTS5` (Full-Text Search 5) extension.
2. **Pre-Normalized Inverted Index**: Apply Arabic text normalization and tokenization once during content packaging/ingestion, populating an FTS5 virtual table indexing `course_id`, `title`, `instructor`, `syllabus`, and `lesson_transcripts`.
3. **Background Query Offloading**: Execute FTS queries asynchronously via a background isolate or database thread, with 250ms query input debouncing.
4. **Ranked Snippet Retrieval**: Utilize SQLite `bm25()` ranking and `snippet()` to return ranked matches with keyword highlight offsets.

## Payoff Trigger
When the curriculum expands beyond 100 courses or when full-text search across lesson transcripts / medical keywords is mandated.

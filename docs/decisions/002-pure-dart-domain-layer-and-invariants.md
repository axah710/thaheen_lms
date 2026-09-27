# ADR-002: Pure Dart Domain Layer and Pedagogical Invariants

- **Status**: Accepted
- **Date**: 2026-09-25
- **Author**: Engineering Team

---

## Context
Educational compliance in health sciences demands strict, verifiable pedagogical logic:
1. Students cannot skip ahead without mastering preceding foundational lessons.
2. Lessons should not be marked complete from accidental taps or short previews.
3. Progress percentage calculations must remain deterministic across courses.

Coupling this logic with Flutter widgets or platform video players creates brittle, hard-to-test code and slow test suites.

## Decision
Implement a pure Dart domain layer completely decoupled from the Flutter widget framework:
1. **Immutable Domain Entities**: `Course`, `Section`, `Lesson`, `CourseProgress`, and `LessonProgress` are pure Dart data structures with value equality.
2. **The 90% Auto-Completion Invariant**:
   $$\text{isCompleted} \iff \text{positionSec} \ge \lceil 0.90 \times \text{durationSec} \rceil$$
   Idempotent and irreversible: seeking backward after reaching 90% leaves the completed status intact. Replaying completed lessons preserves completion.
3. **Sequential Unlock Invariant**:
   Lesson 1 is unlocked by default. Lesson $N$ ($N > 1$) is locked until Lesson $N-1$ is completed, evaluated across section boundaries according to `globalOrderIndex`.
4. **Functional Error Handling**:
   All repository contracts return `Either<Failure, T>` from `package:either_dart`, preventing unchecked exceptions.

## Consequences & Trade-offs
- **Pros**:
  - Fast, deterministic unit tests that run hermetically in milliseconds without hardware or codec dependencies.
  - Zero false triggers or division-by-zero crashes.
- **Cons & Mitigations**:
  - Requires DTO-to-entity mapping in data sources.

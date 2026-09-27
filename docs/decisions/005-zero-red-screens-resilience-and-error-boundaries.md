# ADR-005: Zero Red Screens Fault Tolerance and Global Error Boundary

- **Status**: Accepted
- **Date**: 2026-09-25
- **Author**: Engineering Team

---

## Context
In production mobile apps, unhandled widget exceptions or platform media decoding failures crash into the Flutter framework's "red screen of death" or cause blank screens. In high-stakes health-sciences study sessions, this causes student frustration and loss of study continuity.

## Decision
Enforce a multi-layered fault-tolerance architecture guaranteeing "Zero Red Screens":
1. **Component-Level Media Recovery (`InPlayerErrorCard`)**:
   - If a video asset is corrupted or unsupported, `LessonPlayerCubit` catches the error and transitions to `LessonPlayerError`.
   - The player viewport displays an Arabic card with Retry and Return to Course buttons without crashing.
2. **Empty Course State (`EmptyCourseView`)**:
   - Courses with 0 lessons render an informative, centered Arabic empty state without layout collapse or division-by-zero errors.
3. **Global Crash Interceptor (`CustomErrorWidget`)**:
   - In `main.dart`, `initGlobalErrorBoundary()` overrides Flutter's `ErrorWidget.builder`.
   - Any unexpected layout or rendering exception is intercepted and rendered as a polite, branded Arabic recovery card with clear guidance and debug diagnostic details in development mode.

## Consequences & Trade-offs
- **Pros**:
  - The application never crashes or presents red screens to students.
  - Failures always provide a safe escape route back to the course catalog.
- **Cons & Mitigations**:
  - Requires maintaining dedicated fallback widgets for every error state.

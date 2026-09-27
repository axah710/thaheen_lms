# Clean Architecture Convention

> **Architecture, layer dependencies, and coding rules for Thaheen LMS.**

---

## 1. Layer Separation & Dependency Flow

```text
Presentation Layer (Widgets, Pages, BLoC/Cubit UI bindings)
       │
       ▼
Application Layer (Cubits, Application State, Presentation Models)
       │
       ▼
Domain Layer (Entities, Pure Invariants, Value Objects, Repository Interfaces)
       ▲
       │
Data Layer (DTOs, JSON Serialization, Data Sources, Repository Implementations)
```

### 1.1 Pure Dart Domain Layer
- **Strict Rule**: Files under `domain/` must remain pure Dart.
- Banned in domain: `package:flutter/material.dart`, `package:flutter/widgets.dart`, `BuildContext`, platform channels.
- Allowed: `package:meta/meta.dart` or `package:flutter/foundation.dart` for `@immutable` annotations, mathematical functions, string parsing.
- Domain entities must be immutable (`final` fields, value equality).

### 1.2 Error Handling Pattern
- Use typed `Either<Failure, T>` from `package:either_dart` for repository return signatures.
- Never throw unhandled runtime exceptions across layer boundaries.
- Every `Failure` must provide an informative Arabic error message (`messageArabic`) suitable for direct UI presentation.

### 1.3 Cubit Implementation Pattern
- Cubits must expose typed, immutable states using Dart 3 sealed class hierarchies (`CourseListState`, `CourseDetailsState`, `LessonPlayerState`).
- **Post-Closure Safety**: Every state emission MUST use an `emitSafe(state)` helper checking `if (!isClosed) emit(state);` to prevent framework assertion errors during asynchronous teardown.

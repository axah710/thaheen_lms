# Persistence & Lifecycle Convention

> **Durable local storage, debouncing mechanics, and lifecycle flushing protocols.**

---

## 1. Storage Schema & Keys

- **Durable Storage**: Managed via `LocalStorageService` backed by `SharedPreferences`.
- **Envelope Key**: `thaheen_progress_v1`.
- **Envelope Contract**:
  - `schemaVersion: int` (current: 1).
  - `records: Map<String, LessonProgressDto>` (keyed by `lessonId`).

---

## 2. Hybrid Persistence Engine

Frequent synchronous writes to flash storage during high-frequency playback (e.g., 60fps position updates) cause disk wear and battery drain. The app employs a hybrid debouncing and write-through buffer:

1. **5-Second Continuous Debounce**:
   - As video position updates continuously, updates accumulate in memory.
   - A single write to `SharedPreferences` commits every 5 seconds.
2. **Immediate Write-Through Flush**:
   - The debounce timer is bypassed, and all dirty records are immediately committed to disk upon:
     - User pausing the video (`togglePlayPause()` / `pause()`).
     - User releasing the seek bar slider (`onSeekEnd`).
     - Playback crossing the 90% auto-completion threshold.
     - User navigating back from the player screen (`dispose()`).
     - App transitioning to any background state (`paused`, `inactive`, `hidden`, `detached`).

---

## 3. Flutter Lifecycle Invariant

- `LessonPlayerPage` registers an `AppLifecycleListener`.
- On `onPause`, `onInactive`, `onHide`, or `onDetach`:
  ```dart
  _progressRepository.flush();
  _lessonPlayerCubit.pause();
  ```
- **State Machine Rule**: In widget tests simulating backgrounding, state transitions must follow Flutter's valid sequence: `resumed` $\rightarrow$ `inactive` $\rightarrow$ `hidden` $\rightarrow$ `paused` $\rightarrow$ `detached`. Transitioning directly between non-adjacent states violates framework assertions.

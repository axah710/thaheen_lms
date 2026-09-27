# ADR-004: Durable Local Persistence and Lifecycle Write-Through Buffer

- **Status**: Accepted
- **Date**: 2026-09-25
- **Author**: Engineering Team

---

## Context
Video playback generates continuous position updates (several times per second). Writing each update immediately to flash storage (`SharedPreferences`) causes disk wear, frame stutter, and excessive battery consumption. Conversely, buffering in memory without write-through guarantees risks losing progress if the student backgrounds the app or the OS evicts the process.

## Decision
Implement a hybrid debouncing and write-through persistence engine:
1. **5-Second Playback Debounce**: Continuous playback ticks accumulate in an in-memory dirty buffer and write to disk at most once every 5 seconds.
2. **Immediate Write-Through Triggers**:
   - The dirty buffer is flushed immediately to disk on:
     - Pause (`togglePlayPause()` / `pause()`).
     - Seek bar release (`onSeekEnd`).
     - Crossing the 90% auto-completion threshold.
     - Page exit (`dispose()`).
     - `AppLifecycleListener` transitions: `paused`, `inactive`, `hidden`, and `detached`.
3. **Corrupted JSON Recovery**:
   - Storage corruption is safely caught, reset to an empty envelope, and accompanied by an Arabic SnackBar warning.

## Consequences & Trade-offs
- **Pros**:
  - Near-zero I/O overhead during continuous playback.
  - Zero lost progress upon cold restart, backgrounding, or process termination.
- **Cons & Mitigations**:
  - Requires maintaining in-memory dirty flags and debouncer timers in `ProgressRepositoryImpl`.

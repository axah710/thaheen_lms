# ADR-003: Arabic-First RTL Ergonomics and Unmirrored Media Controls

- **Status**: Accepted
- **Date**: 2026-09-25
- **Author**: Engineering Team

---

## Context
Standard Flutter apps running under Arabic (`ar`) locales often suffer from two common design flaws:
1. Blindly mirroring all UI icons, including media controls (e.g. flipping the play button `▶` into `◀`), which contradicts universal physical time arrow conventions.
2. Mixing Eastern Arabic digits (`٠-٩`) with Western Arabic digits (`0-9`), causing disorientation when reading medical metrics, heart rates, speeds, and timestamps.

## Decision
1. **Global RTL Directionality**: The app root defaults unconditionally to `TextDirection.rtl` with directional spacing (`EdgeInsetsDirectional`).
2. **Selective Icon Mirroring**:
   - Navigation chevrons (back/forward) mirror according to reading direction (`Icons.arrow_back_rounded` with `matchTextDirection: true` points right $\rightarrow$).
   - Media controls explicitly maintain `matchTextDirection: false` (play `▶`, pause, rewind, fast-forward).
3. **Strict Western Arabic Numerals (`0-9`)**:
   - All durations, timestamps (`00:42 / 01:40`), playback speeds (`1.25x`), and percentages (`33%`) use clean Western Arabic digits. Eastern Arabic numerals are strictly banned.

## Consequences & Trade-offs
- **Pros**:
  - Intuitive, culturally authentic Arabic ergonomics without visual awkwardness.
  - Zero ambiguity in medical metric displays.
- **Cons & Mitigations**:
  - Requires explicit verification of `IconData.matchTextDirection` in widget tests.

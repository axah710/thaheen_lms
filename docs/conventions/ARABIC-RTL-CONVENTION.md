# Arabic RTL Ergonomics Convention

> **Authoritative guidelines for RTL layout, typography, directional icons, and numeral systems.**

---

## 1. Directionality & Layout

- **Global Directionality**: The app root unconditionally wraps the widget tree in `Directionality(textDirection: TextDirection.rtl)`.
- **Directional Spacing**:
  - Always use `EdgeInsetsDirectional` (`start`, `end`, `top`, `bottom`) instead of `EdgeInsets.only(left, right)`.
  - Symmetrical margins must use `EdgeInsetsDirectional.symmetric(horizontal: ..., vertical: ...)`.
  - Alignment must use `AlignmentDirectional` (`centerStart`, `centerEnd`) to guarantee proper positioning under RTL.

---

## 2. Icon Directionality Rules

- **Directional Icons (MUST mirror in RTL)**:
  - Navigation back arrows and chevrons point in the natural reading direction.
  - Use `Icons.arrow_back_rounded` with `matchTextDirection: true` (points to the right $\rightarrow$ in RTL).
  - Breadcrumb and syllabus expansion chevrons point to the left ($\leftarrow$) to advance.
- **Media Control Icons (MUST NOT mirror in RTL)**:
  - Universal physical time conventions require video playback to advance from left-to-right in user perception.
  - Explicitly preserve `matchTextDirection: false` on:
    - Play: `Icons.play_arrow_rounded` (points right `▶`)
    - Pause: `Icons.pause_rounded`
    - Fast-Forward: `Icons.forward_10_rounded`
    - Rewind: `Icons.replay_10_rounded`

---

## 3. Numeral Formatting Standards

- **Strict Western Arabic Requirement**:
  - All numbers, timestamps, durations, speeds, and percentages MUST be formatted using standard Western Arabic digits (`0-9`).
  - **Banned**: Eastern Arabic numerals (`٠-٩`).
  - *Rationale*: Medical and health-sciences metrics (e.g. dosages, heart rates, duration timestamps like `01:40`, and speeds like `1.25x`) become ambiguous and prone to misreading when mixed with non-Western numerals.

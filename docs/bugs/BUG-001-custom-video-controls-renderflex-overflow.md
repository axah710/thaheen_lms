# BUG-001: RenderFlex Overflow in CustomVideoControls (2.9 pixels)

- **ID**: `BUG-001`
- **Component**: `CustomVideoControls` (`lib/features/player/presentation/widgets/custom_video_controls.dart`)
- **Severity**: Low (Visual overflow banner in debug mode; 2.9 pixels)
- **Status**: Resolved
- **Date**: 2026-09-25

---

## 1. Issue Description

When opening `LessonPlayerPage` in portrait mode on devices or windows with a 16:9 video viewport constraint ($390\text{px}$ width $\rightarrow 219.4\text{px}$ height), Flutter's rendering library threw a layout overflow exception:

```text
════════ Exception caught by rendering library ═════════════════════════════════
A RenderFlex overflowed by 2.9 pixels on the bottom.
The relevant error-causing widget was:
    Column Column:file:///Users/axah43/Work/thaheen_lms/lib/features/player/presentation/widgets/custom_video_controls.dart:70:20
════════════════════════════════════════════════════════════════════════════════
```

---

## 2. Root Cause Analysis

Inside `CustomVideoControls`, the controls layout used a vertical `Column`:
```dart
Column(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    TopBar,         // ~64px (IconButton 48px + padding 16px)
    CenterButton,   // 64px fixed container
    BottomBar,      // Column with RtlSeekBar (~64px) + FullscreenRow (56px)
  ],
)
```
1. **Vertical Footprint**: Total intrinsic height of the fixed children was $64 + 64 + 64 + 56 = 248\text{px}$.
2. **Viewport Boundary**: In a 16:9 container at $390\text{px}$ screen width, the container height is $390 \times \frac{9}{16} = 219.38\text{px}$.
3. **Redundant Row**: The fullscreen button was placed in an extra `Row` below `RtlSeekBar` instead of being integrated into the timestamp bar.
4. **SafeArea Over-Padding**: `SafeArea` was applied inside `CustomVideoControls` unconditionally, even though the page-level Scaffold already applied SafeArea in portrait mode.

The combined height exceeded the viewport by exactly **2.9 pixels**.

---

## 3. Solution

1. **Inline Trailing Fullscreen Button in `RtlSeekBar`**:
   - Added `trailing: Widget?` parameter to `RtlSeekBar`.
   - Placed the fullscreen button on the **same horizontal line** as the timestamps (`00:42 / 01:40` on the leading side, fullscreen icon button on the trailing side).
   - Removed the separate 48px fullscreen row from `CustomVideoControls`.

2. **Adaptive Flex Play/Pause Button**:
   - Wrapped the center button in `Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: ...)))`.
   - The center area now absorbs all remaining vertical space and dynamically flexes, mathematically preventing `Column` RenderFlex overflows.

3. **Conditional SafeArea**:
   - Restricted `SafeArea` insets to fullscreen mode only:
     ```dart
     SafeArea(
       top: isFullscreen,
       bottom: isFullscreen,
       left: isFullscreen,
       right: isFullscreen,
       child: Column(...),
     )
     ```

4. **Compact Sizing**:
   - Top bar `IconButton` constrained to $40 \times 40$ with `EdgeInsets.zero` padding.
   - Center Play/Pause button resized from 64px to 56px with a 34px icon.

---

## 4. Prevention & Regression Testing

- Added automated regression test in `test/widget/lesson_player_screen_test.dart`:
  ```dart
  testWidgets(
    'CustomVideoControls renders without RenderFlex overflow in constrained viewports',
    (tester) async { ... }
  );
  ```
- All 86 tests pass cleanly with zero RenderFlex overflow assertions.

# ADR-006: Adaptive Flex Video Controls Layout (Preventing 16:9 RenderFlex Overflows)

- **Status**: Accepted
- **Date**: 2026-09-25
- **Author**: Engineering Team

---

## Context
When rendering video player controls over a fixed 16:9 aspect ratio container in portrait mode, the available viewport height on typical mobile devices ($390\text{px}$ width) is only $219.4\text{px}$. The initial controls layout had a fixed top bar ($64\text{px}$), center button ($64\text{px}$), and bottom bar containing `RtlSeekBar` plus an extra fullscreen row ($120\text{px}$), totaling $248\text{px}$ and causing a 2.9px `RenderFlex` overflow exception (BUG-001).

## Decision
Refactor `CustomVideoControls` and `RtlSeekBar` into an adaptive, zero-overflow flex layout:
1. **Inline Fullscreen Toggle**:
   - `RtlSeekBar` accepts a `Widget? trailing` parameter.
   - The fullscreen `IconButton` is placed on the same horizontal row as the duration timestamps (`00:42 / 01:40` on the leading side, fullscreen toggle on the trailing side), completely removing the separate 48px fullscreen row.
2. **Adaptive Flex Play/Pause Button**:
   - Wrap the center play/pause button in `Expanded(child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: ...)))`.
   - The middle area dynamically absorbs all remaining space between top and bottom bars, making vertical RenderFlex overflow mathematically impossible regardless of aspect ratio or window height.
3. **Scoped SafeArea**:
   - Apply `SafeArea` insets only in fullscreen mode (`top: isFullscreen, bottom: isFullscreen, left: isFullscreen, right: isFullscreen`), preventing duplicate padding in portrait mode.

## Consequences & Trade-offs
- **Pros**:
  - Zero `RenderFlex` overflows across all device form factors, split-screen modes, and window sizes.
  - Controls layout looks clean, modern, and aligned with standard video player UX.
- **Cons & Mitigations**:
  - `RtlSeekBar` has slightly tighter vertical track margins.

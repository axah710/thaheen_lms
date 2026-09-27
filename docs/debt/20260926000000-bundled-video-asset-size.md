---
id: DEBT-20260926000000
title: "Bundled Video Asset Packaging Size"
category: "Technical Debt — Architecture / Storage"
severity: "Medium"
first_identified: "2026-09-26"
related_adrs: ["ADR-001"]
payoff_trigger: "When course catalog expands beyond 5 courses (>100 MB assets)"
---

# Bundled Video Asset Packaging Size

## Description
All sample course videos are packaged directly into `assets/videos/` within the Flutter bundle (`anatomy_intro.mp4`, `anatomy_bones.mp4`, `physiology_intro.mp4`, `corrupt_lesson.mp4`).

## Locations
- `pubspec.yaml`
- `assets/videos/`
- `lib/features/course/data/models/lesson_dto.dart`

## Why This Exists
Fulfills **Constitution Principle I (Hermetic Offline Invariant)** by guaranteeing that the LMS functions 100% offline out-of-the-box in airplane mode without requiring initial network access, CDN sync, or background asset downloading.

## Correct Long-Term Fix
Implement a modular local cache storage engine using `path_provider` and an optional WiFi-only content pack downloader that verifies SHA-256 asset checksums before storing clips into the app's sandboxed document directory.

## Payoff Trigger
When the curriculum exceeds 5 distinct medical modules or bundled media size exceeds 100 MB.

---
id: DEBT-20260926000001
title: "Single Active Course Continue Watching Hero Card"
category: "Technical Debt — UX / Application"
severity: "Low"
first_identified: "2026-09-26"
related_adrs: ["ADR-004"]
payoff_trigger: "When users enroll in 3+ concurrent courses"
---

# Single Active Course Continue Watching Hero Card

## Description
The home screen (`CourseListPage`) currently resolves and renders a single "Continue Watching" hero card representing the most-recently accessed unfinished lesson across all courses in the catalog.

## Locations
- `lib/features/course/domain/entities/continue_watching_item.dart` (re-exported via `application/models/continue_watching_item.dart`)
- `lib/features/player/data/repositories/progress_repository_impl.dart` (`resolveContinueWatching`)
- `lib/features/course/presentation/widgets/continue_watching_card.dart`

## Why This Exists
Fulfills User Story 1 (P1 MVP) and FR-002/FR-003 by providing immediate resumption into the learner's most active lesson with minimum cognitive load and clean UI hierarchy.

## Correct Long-Term Fix
Upgrade the hero section into a horizontal `PageView` or carousel of active courses if the learner has started multiple courses concurrently, while prioritizing the most recent one.

## Payoff Trigger
When user analytics or student feedback indicates that over 30% of learners actively juggle 3 or more concurrent clinical courses.

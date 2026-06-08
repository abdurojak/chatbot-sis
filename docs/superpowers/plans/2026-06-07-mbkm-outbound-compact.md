# MBKM Outbound Compact Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the MBKM outbound page into the approved compact dashboard layout.

**Architecture:** Keep the feature in `lib/mbkm_outbound_screen.dart`, adding constructor hooks for widget tests and small helper widgets for summary, state views, compact cards, and details. Keep data models and `MbkmService` unchanged.

**Tech Stack:** Flutter Material widgets, existing `AppThemePalette`, MBKM models/service, `url_launcher`, and Flutter widget tests.

---

### Task 1: Test Compact Dashboard Rendering

**Files:**
- Create: `test/mbkm_outbound_screen_test.dart`
- Modify: `lib/mbkm_outbound_screen.dart`

- [ ] **Step 1: Write failing tests**

Add tests that pump `MbkmOutboundPage` with injected `MbkmResponseData` and verify compact dashboard labels, application card actions, and absence of the rejected header copy.

- [ ] **Step 2: Run failing tests**

Run: `flutter test test/mbkm_outbound_screen_test.dart`

Expected: fail because `MbkmOutboundPage` does not accept injected data yet and still uses the older layout.

- [ ] **Step 3: Implement testability hooks and compact UI**

Add optional `initialData` and `skipInitialLoad` parameters, render the compact header/summary/action/card layout, and keep expanded detail actions.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/mbkm_outbound_screen_test.dart`

Expected: pass.

### Task 2: Verify Static Correctness

**Files:**
- Verify: `lib/mbkm_outbound_screen.dart`
- Verify: `test/mbkm_outbound_screen_test.dart`

- [ ] **Step 1: Format touched Dart files**

Run: `dart format lib/mbkm_outbound_screen.dart test/mbkm_outbound_screen_test.dart`

Expected: formatter completes.

- [ ] **Step 2: Analyze touched files**

Run: `flutter analyze lib/mbkm_outbound_screen.dart test/mbkm_outbound_screen_test.dart`

Expected: no analyzer errors.
